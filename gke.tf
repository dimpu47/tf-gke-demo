locals {
  kubernetes_version_main = var.k8s_version
  gke_master_cidr         = var.gke_master_cidr
}

data "google_client_config" "default" {}

module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version    = "33.1.0"
  project_id = var.project_id
  name       = var.gke_cluster_name
  regional   = true
  region     = var.region
  zones      = var.zones

  network                = module.vpc.network_name
  master_ipv4_cidr_block = local.gke_master_cidr
  subnetwork             = module.vpc.subnets_names[index(module.vpc.subnets_names, "kube")]
  ip_range_pods          = module.vpc.subnets_secondary_ranges[1][0].range_name
  ip_range_services      = module.vpc.subnets_secondary_ranges[1][1].range_name

  release_channel        = "UNSPECIFIED"
  kubernetes_version     = local.kubernetes_version_main
  maintenance_start_time = "06:00" # 2AM Central USA time in UTC

  default_max_pods_per_node = 64
  enable_private_nodes      = true
  enable_private_endpoint   = false
  remove_default_node_pool  = true

  deletion_protection = false

  istio = false

  node_metadata = "GKE_METADATA_SERVER"

  create_service_account = false
  service_account        = google_service_account.gke_nodes.email

  database_encryption = [
    {
      state    = "ENCRYPTED"
      key_name = "projects/${var.project_id}/locations/${var.region}/keyRings/${var.gke_key_ring}/cryptoKeys/${var.gke_enc_key}"
    },
  ]

  #  master_authorized_networks = [
  #    {
  #      cidr_block   = module.vpc.subnets_ips[index(module.vpc.subnets_names, "infra-gauro-dev")]
  #      display_name = module.vpc.subnets_names[index(module.vpc.subnets_names, "infra-gauro-dev")]
  #    },
  #  ]

  node_pools = [
    {
      name         = "default-node-pool"
      node_version = local.kubernetes_version_main

      node_count   = 1
      machine_type = var.machine_type
      disk_type    = "pd-ssd"
      disk_size_gb = var.disk_size_gb

      auto_repair        = var.auto_repair
      auto_upgrade       = var.auto_upgrade
      autoscaling        = var.autoscaling
      initial_node_count = var.initial_node_count
      min_count          = var.min_count
      max_count          = var.max_count
      # only for dev, qa
      preemptible = false
    },
    # {
    #   name         = "ai-node-pool"
    #   node_version = local.kubernetes_version_main

    #   node_count   = 1
    #   machine_type = var.machine_type_ai
    #   disk_type    = "pd-ssd"
    #   disk_size_gb = var.disk_size_gb

    #   auto_repair        = var.auto_repair
    #   auto_upgrade       = var.auto_upgrade
    #   autoscaling        = var.autoscaling
    #   initial_node_count = var.initial_node_count
    #   min_count          = var.min_count
    #   max_count          = var.max_count
    #   # only for dev, qa
    #   preemptible        = false
    # }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    default-node-pool = []
  }

  node_pools_labels = {
    all = {
      env = var.env
    }

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {}
  }

  node_pools_tags = {
    all = ["${var.env}"]

    default-node-pool = [
      "default",
    ]
  }
}


resource "null_resource" "deploy_argo" {

  provisioner "local-exec" {
    command = <<EOF
    SA_EMAIL=tofu-$env@$project_id.iam.gserviceaccount.com
    gcloud auth activate-service-account $SA_EMAIL --key-file=creds/$env/key.json
    gcloud components install kubectl --quiet
    gcloud container clusters list --filter=status:RUNNING  --filter=name:$cluster_name
    gcloud container clusters get-credentials $cluster_name --region $cluster_region

    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.12.6/manifests/$(if [ "$ha" = true ]; then echo "ha/install.yaml"; else echo "install.yaml"; fi)
    EOF

    environment = {
      cluster_name   = "${var.gke_cluster_name}"
      cluster_region = "${var.region}"
      project_id     = "${var.project_id}"
      env            = "${var.env}"
      ha             = "${var.argo_ha}"
    }
  }

  depends_on = [module.gke]
}


################
### OUTPUTS ###
################

output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = module.gke.location
}


output "endpoint" {
  sensitive   = true
  description = "Cluster endpoint"
  value       = module.gke.endpoint
}