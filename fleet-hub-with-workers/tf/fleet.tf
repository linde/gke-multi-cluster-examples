
resource "google_gke_hub_fleet" "fleet" {
  project = var.gcp_project

  depends_on = [
    time_sleep.post_services_wait
  ]
}
