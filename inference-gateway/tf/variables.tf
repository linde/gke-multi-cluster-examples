
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

// not really a var but helpful
resource "random_id" "rand" {
  byte_length = 4
}


variable "cluster_release_channel" {
  type    = string
  default = "RAPID"
}

variable "cluster_min_master_version" {
  type    = string
  default = "1.32.3-gke.1170000"
}
