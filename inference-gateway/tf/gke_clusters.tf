

resource "google_container_cluster" "worker" {

  project  = var.gcp_project
  location = var.worker_location
  name     = local.cluster_app

  enable_autopilot = true

  fleet {
    project = var.gcp_project
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  min_master_version = var.cluster_min_master_version

  release_channel {
    channel = var.cluster_release_channel
  }

  depends_on = [
    time_sleep.post_services_wait
  ]

  deletion_protection = false
}
