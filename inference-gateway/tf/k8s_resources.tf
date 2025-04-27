

resource "helm_release" "inference_crds" {
  provider = helm.worker_0

  name  = "inference-workload-crds"
  chart = "${var.helm_chart_root}/inference-gateway-crds"

}

# https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-with-gke-inference-gateway#create-inference-pool
resource "helm_release" "inferencepool" {
  provider = helm.worker_0

  name = local.cluster_app

  repository = "oci://registry.k8s.io/gateway-api-inference-extension/charts"
  chart      = "inferencepool"
  version    = "v0.3.0"

  set {
    name  = "inferencePool.modelServers.matchLabels.app"
    value = local.cluster_app
  }

  set {
    name  = "provider.name"
    value = "gke"
  }
}

resource "helm_release" "inference_workload" {
  provider = helm.worker_0

  name  = "inference-workload"
  chart = "${var.helm_chart_root}/inference-workload"

  wait = false

  set {
    name  = "app"
    value = local.cluster_app
  }

  set {
    name  = "model"
    value = var.model
  }

  depends_on = [helm_release.inference_crds, helm_release.inferencepool]
}

