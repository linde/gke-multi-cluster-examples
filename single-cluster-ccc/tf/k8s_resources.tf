

resource "helm_release" "ccc" {
  provider = helm.primary_cluster

  name  = "ccc"
  chart = "${var.helm_chart_root}/ccc-example"

  wait = false
}

