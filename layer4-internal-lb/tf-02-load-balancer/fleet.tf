

# adding MCS to get its firewall rules (which i cant add myself bc of latchkey)
# it adds: 35.191.0.0/16, 130.211.0.0/22, 10.125.0.0/17

resource "google_gke_hub_feature" "mcs" {
  project  = local.gcp_project
  name     = "multiclusterservicediscovery"
  location = "global"

}

