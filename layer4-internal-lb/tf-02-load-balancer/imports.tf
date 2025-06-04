data "terraform_remote_state" "project_level" {
  backend = "local"

  config = {
    path = "../tf-01-clusters-and-workload/terraform.tfstate"
  }
}

locals {
  gcp_project     = data.terraform_remote_state.project_level.outputs.gcp_project
  worker_location = data.terraform_remote_state.project_level.outputs.worker_location
  cluster_name    = data.terraform_remote_state.project_level.outputs.cluster_name
  redis_port      = data.terraform_remote_state.project_level.outputs.redis_port
  neg_name        = data.terraform_remote_state.project_level.outputs.neg_name

  cluster_network    = data.terraform_remote_state.project_level.outputs.network
  cluster_subnetwork = data.terraform_remote_state.project_level.outputs.subnetwork
}


