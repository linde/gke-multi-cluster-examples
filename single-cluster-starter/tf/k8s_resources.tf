

resource "helm_release" "inference_crds" {
  provider = helm.worker_0

  name  = "ccc-example"
  chart = "${var.helm_chart_root}/ccc-example"

}

