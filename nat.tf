resource "google_compute_router" "nat_router" {
  name    = "nat-router-main"
  network = module.vpc.network_self_link
  region  = var.region

  depends_on = [
    module.vpc
  ]
}

resource "google_compute_router_nat" "main" {
  name   = "nat-gw-main"
  router = google_compute_router.nat_router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = var.subnets
    content {
      name                    = lookup(subnetwork.value, "subnet_name", "")
      source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
    }
  }

  log_config {
    enable = false
    filter = "ALL"
  }

  depends_on = [
    google_compute_router.nat_router
  ]
}