variable "project_id" {
  type        = string
  description = "Id of the project all resources go under"
  default     = "your-project-id"
}

variable "region" {
  type        = string
  description = "GCP region for the resources"
  default     = "us-central1"
}
variable "zones" {
  type        = list(string)
  description = "GCP zones for the resources"
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "gke_cluster_name" {
  default = "demo-gke"
}

variable "env" {
  default = "sandbox"
}

variable "network_name" {
  type        = string
  default     = "demo-demo-nw"
  description = "VPC Network Name"
}

variable "subnets" {
  type = any
  default = [
    {
      subnet_name           = "infra-demo-sandbox"
      subnet_ip             = "10.10.0.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "kube"
      subnet_ip             = "10.20.0.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = "true"
    },

  ]
  description = "VPC subnets for GKE cluster"
}

variable "secondary_ranges" {
  type = any
  default = {
    # v--- This is the subnet name associated to alias ranges
    kube = [
      {
        range_name    = "kube-pods"
        ip_cidr_range = "10.0.0.0/18"
      },
      {
        range_name    = "kube-svcs"
        ip_cidr_range = "10.40.0.0/24"
      },
    ]
  }
  description = "k8s POD and SVC IP Ranges"
}

variable "machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "VM machine type for GKE nodes"
}
variable "machine_type_ai" {
  type        = string
  default     = "a2-highgpu-1g"
  description = "VM machine type for GKE nodes"
}

variable "k8s_version" {
  type        = string
  default     = "1.30.5-gke.1014001"
  description = "GKE version"
}

variable "gke_master_cidr" {
  type        = string
  default     = "192.168.15.224/28"
  description = "IP Range for GKE Master Nodes"
}

variable "disk_size_gb" {
  default = 100
}

variable "argo_ha" {
  type        = bool
  default     = false
  description = "whether to deploy argo in ha mode or not"
}

variable "autoscaling" {
  type    = bool
  default = true
}
variable "auto_repair" {
  type    = bool
  default = true
}
variable "auto_upgrade" {
  type    = bool
  default = true
}
variable "initial_node_count" {
  type    = string
  default = "1"
}
variable "min_count" {
  type    = string
  default = "1"
}
variable "max_count" {
  type    = string
  default = "10"
}
variable "gcp_sa_name" {
  default = "gke-nodes"
}

variable "gke_key_ring" {
  default = "gke-sandbox-ring"
}
variable "gke_enc_key" {
  default = "gke-sandbox-enc-key"
}

variable "gke_nodes_sa_roles" {
  type = set(string)
  default = [
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/stackdriver.resourceMetadata.writer",
  ]
}
