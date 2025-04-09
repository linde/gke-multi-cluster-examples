
resource "helm_release" "flux" {
  provider = helm.hub

  name             = "flux2"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  version          = "2.12.4"
  namespace        = "flux-system"
  create_namespace = true
}

resource "helm_release" "hub" {
  provider = helm.hub

  name  = "hub"
  chart = "${var.helm_chart_root}/hub"

  set {
    name  = "git.repo"
    value = "https://github.com/linde/acm-minimal.git"
  }
  set {
    name  = "git.path"
    value = "./config-root"
  }

  depends_on = [helm_release.flux]
}

# resource "kubernetes_config_map" "k8s_tf_marker" {
#   provider = kubernetes.hub
#   metadata {
#     namespace = "default"
#     name      = "k8s-tf-marker"
#   }

#   data = {
#     marker = "true"
#   }
# }

