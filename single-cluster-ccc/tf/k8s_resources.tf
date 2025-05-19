

resource "helm_release" "ccc" {
  provider = helm.primary_cluster

  name  = "ccc"
  chart = "${var.helm_chart_root}/ccc-example"

  namespace = "default"
  lint = true
  wait = false
}

// this is based on direction in this public GKE doc
// https://cloud.google.com/kubernetes-engine/docs/tutorials/autoscaling-metrics#step1
resource "helm_release" "stackdriver-custom-metrics" {
  provider = helm.primary_cluster

  name  = "stackdriver-custom-metrics"
  chart = "${var.helm_chart_root}/stackdriver-custom-metrics"

  lint = true
}
