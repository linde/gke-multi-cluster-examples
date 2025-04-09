terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.26.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}


provider "google" {}
data "google_client_config" "default" {}

provider "helm" {
  alias = "hub"
  kubernetes {
    host                   = "https://${google_container_cluster.hub.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.hub.master_auth[0].cluster_ca_certificate)  
  }
}


provider "kubernetes" {
  alias                  = "hub"
  host                   = "https://${google_container_cluster.hub.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.hub.master_auth[0].cluster_ca_certificate)
}

