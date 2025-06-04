

resource "google_container_cluster" "cluster" {

  for_each = toset(var.cluster_locations)

  project  = var.gcp_project
  location = each.value
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
      service_account = google_service_account.cluster_sa.email
    }
  }

  depends_on = [
    time_sleep.post_services_wait
  ]

  deletion_protection = false
}

