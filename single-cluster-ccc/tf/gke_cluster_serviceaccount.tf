

resource "google_service_account" "worker" {

  project      = var.gcp_project
  account_id   = "${local.cluster_name}-sa"
  display_name = "Service Account for the ${local.cluster_name} cluster"

}

resource "google_project_iam_member" "worker_sa" {

  for_each = toset([
    "roles/container.defaultNodeServiceAccount",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",
    "roles/compute.networkUser",
  ])
  role    = each.value
  project = var.gcp_project
  member  = "serviceAccount:${google_service_account.worker.email}"
}


data "google_project" "cluster_project" {
  project_id = var.gcp_project
}

resource "google_project_iam_member" "metrics_ksa" {
  role    = "roles/monitoring.viewer"
  project = var.gcp_project
  member  = "principal://iam.googleapis.com/projects/${data.google_project.cluster_project.number}/locations/global/workloadIdentityPools/${var.gcp_project}.svc.id.goog/subject/ns/custom-metrics/sa/custom-metrics-stackdriver-adapter"
}
