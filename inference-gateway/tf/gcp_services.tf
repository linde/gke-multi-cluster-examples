
locals {
  disable_on_destroy = false
}


resource "google_project_service" "services" {
  project = var.gcp_project
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "trafficdirector.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "multiclusteringress.googleapis.com",
    "gkehub.googleapis.com",
    "monitoring.googleapis.com",

    "networkservices.googleapis.com",  # we need this but might not need
    "servicenetworking.googleapis.com",

  ])
  service            = each.value
  disable_on_destroy = false
}


// resources should depends_on this if they depend on services

resource "time_sleep" "post_services_wait" {
  create_duration = "15s"
  depends_on = [
    google_project_service.services
  ]
}