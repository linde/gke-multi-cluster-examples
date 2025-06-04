
variable "gcp_project" {
  type = string
}

variable "worker_prefix" {
  type    = string
  default = "l4ilb"
}

variable "worker_location" {
  type    = string
  default = "us-west1"
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
  cluster_name = "${var.worker_prefix}-${random_id.rand.hex}"
  neg_name     = "${local.cluster_name}-neg"
}

