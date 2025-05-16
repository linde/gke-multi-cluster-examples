

# Create a GKE Standard regional cluster 
resource "google_container_cluster" "primary_cluster" {
  name     = local.cluster_name
  project  = var.gcp_project
  location = var.worker_location

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  node_config {
    service_account = google_service_account.worker.email
  }
  

  cluster_autoscaling {
    enabled = true

    autoscaling_profile = "OPTIMIZE_UTILIZATION" # this helps scale up/down faster

    # respective min/max resource limits cluster-wide, required to exist for auto provisioning
    resource_limits {
      resource_type = "cpu"
      minimum       = 1     # Minimum total cluster CPU
      maximum       = 99999 # Maximum total cluster CPU
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1     # Minimum total cluster memory (in GB)
      maximum       = 99999 # Maximum total cluster memory (in GB)
    }

    auto_provisioning_defaults {
      service_account = google_service_account.worker.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }
    
  }

  deletion_protection = false

  depends_on = [time_sleep.post_services_wait]
}

