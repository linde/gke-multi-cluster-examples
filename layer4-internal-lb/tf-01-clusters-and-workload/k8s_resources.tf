

# TODO rename this from previous
resource "helm_release" "redis" {
  provider = helm.cluster_0

  name  = "redis"
  chart = "${var.helm_chart_root}/redis-with-neg"

  wait = false

  set {
    name  = "negName"
    value = local.neg_name
  }

  set {
    name  = "redisPort"
    value = var.redis_port
  }
}
