
variable "gcp_project" {
  type = string
}

variable "cluster_prefix" {
  type    = string
  default = "l4ilb"
}


variable "cluster_locations" {
  type    = list(string)
  default = ["us-west1", "us-east1"]
}
locals {
  # vars so people can reason with the clusters by name not subscript
  region_west = var.cluster_locations[0]
  region_east = var.cluster_locations[1]
}

variable "helm_chart_root" {
  type    = string
  default = "../helm-charts"
}

variable "redis_port" {
  type    = number
  default = 6379
}


// not really a var but helpful
resource "random_id" "rand" {
  byte_length = 4
}

locals {
  cluster_name = "${var.cluster_prefix}-${random_id.rand.hex}"
  neg_name     = "${local.cluster_name}-neg"
}

