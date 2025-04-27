
variable "gcp_project" {
  type = string
}

variable "worker_prefix" {
  type    = string
  default = "infg8way-tf"
}

variable "worker_location" {
  type    = string
  default = "us-west1"
}


variable "helm_chart_root" {
  type    = string
  default = "../helm-charts"
}


variable "cluster_release_channel" {
  type    = string
  default = "RAPID"
}

variable "cluster_min_master_version" {
  type    = string
  default = "1.32.3-gke.1170000"
}

variable "model" {
  type = string
  default = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
  
}

// not really a var but helpful
resource "random_id" "rand" {
  byte_length = 4
}

locals {
  cluster_app = "${var.worker_prefix}-${random_id.rand.hex}"
}
