
output "gcp_project" {
  value = var.gcp_project
}

output "worker_location" {
  value = var.worker_location
}

output "cluster_name" {
  value = local.cluster_name
}

output "redis_port" {
  value = var.redis_port
}

output "neg_name" {
  value = local.neg_name
}

output "network" {
  value = google_container_cluster.cluster.network
}

output "subnetwork" {
  value = google_container_cluster.cluster.subnetwork
}