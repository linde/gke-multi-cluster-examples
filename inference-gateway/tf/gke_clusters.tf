

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


// need to create a proxy subnet in the same subnet and region as our cluster subnet for the gateway

data "google_compute_subnetwork" "worker_subnet" {
  self_link = "https://www.googleapis.com/compute/v1/${google_container_cluster.worker.subnetwork}"
}

resource "google_compute_subnetwork" "proxy" {
  project       = data.google_compute_subnetwork.worker_subnet.project
  region        = data.google_compute_subnetwork.worker_subnet.region
  network       = data.google_compute_subnetwork.worker_subnet.network
  name          = "${local.cluster_app}-proxy-subnet"
  ip_cidr_range = "10.3.0.0/22" 
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}
