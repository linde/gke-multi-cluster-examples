


resource "google_container_cluster" "worker_clusters" {

  for_each = toset(var.worker_locations)

  project  = var.gcp_project
  location = each.value
  name     = "${var.cluster_prefix}-${random_id.rand.hex}-${each.value}"

  enable_autopilot = true

  fleet {
    project = var.gcp_project
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  depends_on = [
    time_sleep.post_services_wait
  ]

  deletion_protection = false
}


resource "google_container_cluster" "hub" {

  project  = var.gcp_project
  location = var.hub_location
  name     = "hub-${random_id.rand.hex}"

  resource_labels = {
    // this will designate this cluster as a hub and it will get 
    // cluster profile resources synced to it for all fleet clusters.
    "fleet-clusterinventory-management-cluster" = "true"
  }

  enable_autopilot = true

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.hub.email
    }
  }

  fleet {
    project = var.gcp_project
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  deletion_protection = false
}
