

resource "helm_release" "inference_crds" {
  provider = helm.worker_0

  name  = "inference-workload-crds"
  chart = "${var.helm_chart_root}/inference-gateway-crds"

}

# https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-with-gke-inference-gateway#create-inference-pool
resource "helm_release" "inferencepool" {
  provider = helm.worker_0

  name  = "inferencepool"

  repository = "oci://registry.k8s.io/gateway-api-inference-extension/charts"
  chart = "inferencepool"
  version = "v0.3.0" 

  set {
    name = "inferencePool.modelServers.matchLabels.app"
    # value = "vllm-llama3-8b-instruct"
    value = ""
  }

  set {
    name = "provider.name"
    value = "gke"
  }
}

resource "helm_release" "inference_workload" {
  provider = helm.worker_0

  name  = "inference-workload"
  chart = "${var.helm_chart_root}/inference-workload"

  set {
    name = "hf_token"
    value = var.hf_token
  }

  wait = false

  depends_on = [ helm_release.inference_crds, helm_release.inferencepool ]
}

