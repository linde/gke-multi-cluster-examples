
data "google_project" "hub" {
  project_id = var.gcp_project
}

resource "google_service_account" "hub" {
  project      = var.gcp_project
  account_id   = "${var.cluster_prefix}-hub"
  display_name = "${var.cluster_prefix} hub cluster service account"
}

resource "google_project_iam_member" "hub_gsa" {

  for_each = toset([
    "roles/container.defaultNodeServiceAccount",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",
  ])

  project = data.google_project.hub.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.hub.email}"
}