terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }

    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "google" {}
data "google_client_config" "default" {}


// the following are k8s specific providers, annoyingly one per cluster 
// which we access via locals to shorten resource paths


locals {
  cluster_west = google_container_cluster.cluster[local.region_west]
  cluster_east = google_container_cluster.cluster[local.region_east]
}
provider "helm" {
  alias = "cluster_west"
  kubernetes {
    host                   = local.cluster_west.endpoint
    client_key             = local.cluster_west.master_auth[0].client_key
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(local.cluster_west.master_auth[0].cluster_ca_certificate)
  }
}

provider "helm" {
  alias = "cluster_east"
  kubernetes {
    host                   = local.cluster_east.endpoint
    client_key             = local.cluster_east.master_auth[0].client_key
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(local.cluster_east.master_auth[0].cluster_ca_certificate)
  }
}
