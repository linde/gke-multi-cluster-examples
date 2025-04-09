
variable "gcp_project" {
  type = string
}

variable "cluster_prefix" {
  type    = string
  default = "fluxfleet-tf"
}

variable "worker_locations" {
  type    = list(string)
  default = ["us-west1"] #, "us-east1"]
}

variable "hub_location" {
  type    = string
  default = "us-central1"
}

variable "helm_chart_root" {
  type    = string
  default = "../helm-charts"
}

# not really a variable but used like one
resource "random_id" "rand" {
  byte_length = 4
}