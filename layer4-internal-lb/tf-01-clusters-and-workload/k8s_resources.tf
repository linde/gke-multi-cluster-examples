

resource "helm_release" "redis_west" {
  provider = helm.cluster_west

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

resource "helm_release" "redis_east" {
  provider = helm.cluster_east

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
