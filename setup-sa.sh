#!/bin/bash
set -e

# Prompt for environment input
read -p "Enter environment name (e.g., sandbox, stage, prod): " ENV

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
    --display-name="tofu-$ENV" > /dev/null 2>&1
}

# Function to add IAM policy bindings
add_policy_binding() {
  local role=$1
  echo "Assigning role $role..."
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role" > /dev/null 2>&1
}


# Function to delete older service account keys
delete_old_keys() {
  echo "Deleting old service account keys for $SA_EMAIL..."
  # List the keys for the service account
  old_keys=$(gcloud iam service-accounts keys list --iam-account="$SA_EMAIL" --format="value(name)")
  
  # Delete each key
  for key in $old_keys; do
    echo "Deleting key $key"
    gcloud iam service-accounts keys delete "$key" --iam-account="$SA_EMAIL" --quiet > /dev/null 2>&1
  done
}


# Check if the user wants to create the service account
if [[ "$CREATE_SA" == "yes" ]]; then
  create_service_account
fi

# Assign roles by calling the function
add_policy_binding "roles/compute.admin"
add_policy_binding "roles/container.admin"
add_policy_binding "roles/iam.serviceAccountTokenCreator"
add_policy_binding "roles/storage.admin"
add_policy_binding "roles/iam.serviceAccountAdmin"
add_policy_binding "roles/iam.serviceAccountUser"

echo "Roles assigned successfully to $SA_EMAIL in project $PROJECT_ID."

echo "Fetching key file for $SA_EMAIL"
gcloud iam service-accounts keys create key.json --iam-account=$SA_EMAIL --key-file-type=json
delete_old_keys

echo "We're done setting up creds!"