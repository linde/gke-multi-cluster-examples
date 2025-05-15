

resource "google_container_cluster" "worker" {

  project  = var.gcp_project
  location = var.worker_location
  name     = local.cluster_name

  enable_autopilot = true

  fleet {
    project = var.gcp_project
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.worker.email
    }
  }

  depends_on = [
    time_sleep.post_services_wait
  ]

  deletion_protection = false
}

