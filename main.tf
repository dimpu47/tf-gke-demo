# Create custom network
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "9.3.0"

  project_id   = var.project_id
  network_name = var.network_name

  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges
}

output "snet_sec" {
  value     = module.vpc.subnets_secondary_ranges
  sensitive = true
}