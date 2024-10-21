#!/bin/bash
set -e

# Prompt for environment input
read -p "Enter environment name (e.g., sandbox, prod): " ENV

# Prompt to create service account
read -p "Do you want to create the service account? (yes/no): " CREATE_SA

# Variables
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
    --format="value(projectNumber)")
SA_NAME="tofu-$ENV"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"


# Function to create service account if user chooses 'yes'
create_service_account() {
  echo "Creating service account: $SA_EMAIL"
  gcloud iam service-accounts create "$SA_NAME" \
    --description="Service account for $ENV environment" \
    --display-name="tofu-$ENV"
}

# Check if the user wants to create the service account
if [[ "$CREATE_SA" == "yes" ]]; then
  create_service_account
fi

# Assign Compute Admin role
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/compute.admin"

# Assign Kubernetes Engine Admin role
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.admin"

# Assign Service Account Token Creator role
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.serviceAccountTokenCreator"

# Assign Storage Admin role
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"

echo "Roles assigned successfully to $SA_EMAIL in project $PROJECT_ID."

echo "Fetching key file for $SA_EMAIL"
gcloud iam service-accounts keys create key.json --iam-account=$SA_EMAIL --key-file-type=json

echo "We're done setting up creds!"