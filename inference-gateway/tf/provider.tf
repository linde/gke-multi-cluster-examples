terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.26.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "google" {}
data "google_client_config" "default" {}


// the following are k8s specific providers, annoyingly one per cluster 
// which we access via locals to shorten resource paths

provider "helm" {
  alias = "worker_0"
  kubernetes {
    host                   = google_container_cluster.worker.endpoint
    client_key             = google_container_cluster.worker.master_auth[0].client_key
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.worker.master_auth[0].cluster_ca_certificate)
  }
}
