
#
# Service Account for GKE nodes
#------------------------------
resource "google_service_account" "gke_nodes" {
  account_id   = var.gcp_sa_name
  project      = module.vpc.project_id
  display_name = "GKE Nodes (Managed by play-net Terraform)"
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = var.gke_nodes_sa_roles
  role     = each.value
  project  = module.vpc.project_id
  member   = "serviceAccount:${google_service_account.gke_nodes.email}"
}