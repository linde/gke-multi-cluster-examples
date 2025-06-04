
output "gcp_project" {
  value = var.gcp_project
}

output "worker_locations" {
  value = var.cluster_locations
}

output "cluster_name" {
  value = local.cluster_name
}

output "cluster_serviceaccount" {
  value = google_service_account.cluster_sa.email
}

output "redis_port" {
  value = var.redis_port
}

output "neg_name" {
  value = local.neg_name
}


# both west and east are using default/default, so just pick one for this
output "network" {
  value = local.cluster_west.network
}

output "subnetwork" {
  value = local.cluster_west.subnetwork
}