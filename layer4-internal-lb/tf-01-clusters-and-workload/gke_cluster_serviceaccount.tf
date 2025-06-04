

resource "google_service_account" "cluster_sa" {

  project      = var.gcp_project
  account_id   = "${local.cluster_name}-sa"
  display_name = "Service Account for the ${local.cluster_name} cluster"

}

resource "google_project_iam_member" "cluster_sa_rolebindings" {

  for_each = toset([
    "roles/container.defaultNodeServiceAccount",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",
    "roles/compute.networkUser",
  ])
  role    = each.value
  project = var.gcp_project
  member  = "serviceAccount:${google_service_account.cluster_sa.email}"
}
