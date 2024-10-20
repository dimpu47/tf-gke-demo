# tf-gke-domo

This repository provides a demo of using Terraform to deploy resources on Google Kubernetes Engine (GKE). The demo highlights key steps and configurations required for setting up a GKE cluster using Terraform and managing it effectively.

## Prerequisites

You should have following tools installed on your system: 

- Tofu: [installation guide](https://opentofu.org/docs/intro/install/) 
- gcloud CLI: [installation guide](https://cloud.google.com/sdk/docs/install#linux)
- gsutil CLI: [installation guide](https://cloud.google.com/storage/docs/gsutil_install)
- kubectl: [installation guide](https://kubernetes.io/docs/tasks/tools/)
- argo CLI: [installation guide](https://argo-cd.readthedocs.io/en/stable/cli_installation)
- terraform-dcs: [installation guide](https://github.com/terraform-docs/terraform-docs?tab=readme-ov-file#installation) (optional)

## Usage

### Access to remote state bucket
To be able to view content of statefile usng `gsutil`
```
ENV=sandbox
BUCKET=gauro-$ENV-tfstate
gsutil iam ch user:<your-eamil-id>:objectAdmin gs://$BUCKET
gsutil cat gs://$BUCKET/tofu/state/$ENV/default.tfstate
```

### KMS Setup for Database (etcd) Encryption

You need to do following steps prior to proviosning GKE cluster using the config in this repo

> FYR: [application layer secrets](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets#gcloud_1)

```
gcloud kms keyrings create gke-$ENV-ring \                                                   
    --location us-central1 \
    --project $(gcloud config get-value project)
```

```
gcloud kms keys create gke-$ENV-enc-key \                                                
    --location us-central1 \
    --keyring gke-$ENV-ring \                   
    --purpose encryption \
    --project $(gcloud config get-value project)
```

```
gcloud kms keys add-iam-policy-binding gke-$ENV-enc-key \                                
  --location us-central1 \  
  --keyring gke-$ENV-ring \                   
  --member serviceAccount:service-708112334541@container-engine-robot.iam.gserviceaccount.com \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
  --project $(gcloud config get-value project)
```

### Init, Plan & Apply
```
ENV=sandbox
BUCKET=gauro-$ENV-tfstate
PROJECT_ID=$(gcloud config get-value project)
SA_NAME=tofu@$PROJECT_ID.iam.gserviceaccount.com

# fetch gcp serviceaccount key
gcloud iam service-accounts keys create key.json --iam-account=$SA_NAME --key-file-type=json

# generate tfvars
tf-docs tfvars hcl . > $ENV.tfvars


tofu init -backend-config="bucket=$BUCKET" -backend-config="prefix=$ENV -backend-config="credentials=key.json"
tofu workspace select gauro-$ENV
tofu plan -var-file $ENV-tfvars -out plan.out
tofu apply -var-file $ENV-tfvars -out plan.out
```



## [High Level Architecure](https://www.mermaidchart.com/raw/b88b3ae6-7d9f-4abb-abbc-651e3f29b91d?theme=light&version=v0.1&format=svg)

```mermaid
graph TD;
    A[GitHub Actions - Terraform Repo] -->|Provisions GKE| B[Private GKE Cluster];
    A -->|Deploys ArgoCD| C[ArgoCD on GKE];
    D[Microservice Repo Backend & Frontend] -->|Build & Push Docker Images| E[Docke Registry/GCR];
    D -->|Update manifests| F[K8s Config Repo];
    F -->|Manifests Update| C;
    C -->|Syncs with GKE| B;
    
    subgraph Terraform Repo
        A
    end
    
    subgraph GKE Cluster
        B
        C
    end
    
    subgraph Microservice Repo
        D
    end
    
    subgraph K8s Config Repo
        F
    end

```



## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.7.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.16.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_enabled_google_apis"></a> [enabled\_google\_apis](#module\_enabled\_google\_apis) | terraform-google-modules/project-factory/google//modules/project_services | ~> 17.0.0 |
| <a name="module_gke"></a> [gke](#module\_gke) | terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster | 33.1.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-google-modules/network/google | 9.3.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_router.nat_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_project_iam_member.gke_nodes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.gke_nodes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.configure_kubectl](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_repair"></a> [auto\_repair](#input\_auto\_repair) | n/a | `bool` | `true` | no |
| <a name="input_auto_upgrade"></a> [auto\_upgrade](#input\_auto\_upgrade) | n/a | `bool` | `true` | no |
| <a name="input_autoscaling"></a> [autoscaling](#input\_autoscaling) | n/a | `bool` | `true` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | n/a | `number` | `100` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | `"staging"` | no |
| <a name="input_gcp_sa_name"></a> [gcp\_sa\_name](#input\_gcp\_sa\_name) | n/a | `string` | `"gke-nodes"` | no |
| <a name="input_gke_cluster_name"></a> [gke\_cluster\_name](#input\_gke\_cluster\_name) | n/a | `string` | `"gauro-gke"` | no |
| <a name="input_gke_enc_key"></a> [gke\_enc\_key](#input\_gke\_enc\_key) | n/a | `string` | `"gke-sandbox-enc-key"` | no |
| <a name="input_gke_key_ring"></a> [gke\_key\_ring](#input\_gke\_key\_ring) | n/a | `string` | `"gke-sandbox-ring"` | no |
| <a name="input_gke_master_cidr"></a> [gke\_master\_cidr](#input\_gke\_master\_cidr) | IP Range for GKE Master Nodes | `string` | `"192.168.15.224/28"` | no |
| <a name="input_gke_nodes_sa_roles"></a> [gke\_nodes\_sa\_roles](#input\_gke\_nodes\_sa\_roles) | n/a | `set(string)` | <pre>[<br>  "roles/monitoring.viewer",<br>  "roles/monitoring.metricWriter",<br>  "roles/logging.logWriter",<br>  "roles/stackdriver.resourceMetadata.writer"<br>]</pre> | no |
| <a name="input_initial_node_count"></a> [initial\_node\_count](#input\_initial\_node\_count) | n/a | `string` | `"1"` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | GKE version | `string` | `"1.19.9-gke.1900"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | VM machine type for GKE nodes | `string` | `"e2-standard-2"` | no |
| <a name="input_machine_type_ai"></a> [machine\_type\_ai](#input\_machine\_type\_ai) | VM machine type for GKE nodes | `string` | `"e2-standard-2"` | no |
| <a name="input_max_count"></a> [max\_count](#input\_max\_count) | n/a | `string` | `"10"` | no |
| <a name="input_min_count"></a> [min\_count](#input\_min\_count) | n/a | `string` | `"1"` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | VPC Network Name | `string` | `"gauro-demo-nw"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Id of the project all resources go under | `string` | `"fluid-stratum-296023"` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the resources | `string` | `"us-central1"` | no |
| <a name="input_secondary_ranges"></a> [secondary\_ranges](#input\_secondary\_ranges) | k8s POD and SVC IP Ranges | `any` | <pre>{<br>  "kube": [<br>    {<br>      "ip_cidr_range": "10.0.0.0/18",<br>      "range_name": "kube-pods"<br>    },<br>    {<br>      "ip_cidr_range": "10.40.0.0/24",<br>      "range_name": "kube-svcs"<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | VPC subnets for GKE cluster | `any` | <pre>[<br>  {<br>    "subnet_ip": "10.10.0.0/24",<br>    "subnet_name": "infra-gauro-sandbox",<br>    "subnet_private_access": "true",<br>    "subnet_region": "us-central1"<br>  },<br>  {<br>    "subnet_ip": "10.20.0.0/24",<br>    "subnet_name": "kube",<br>    "subnet_private_access": "true",<br>    "subnet_region": "us-central1"<br>  }<br>]</pre> | no |
| <a name="input_zones"></a> [zones](#input\_zones) | GCP zones for the resources | `list(string)` | <pre>[<br>  "us-central1-a",<br>  "us-central1-b",<br>  "us-central1-c"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Cluster endpoint |
| <a name="output_location"></a> [location](#output\_location) | Cluster location (region if regional cluster, zone if zonal cluster) |
| <a name="output_snet_sec"></a> [snet\_sec](#output\_snet\_sec) | n/a |
