
resource "google_compute_subnetwork" "proxy_subnet" {
  project       = local.gcp_project
  region        = local.worker_location
  name          = "${local.cluster_name}-proxy-subnet"
  network       = local.cluster_network
  ip_cidr_range = "10.2.0.0/24"
  role          = "ACTIVE"
  purpose       = "REGIONAL_MANAGED_PROXY"
}

resource "google_compute_firewall" "allow_proxy_to_backends" {
  project                 = local.gcp_project
  name                    = "${local.cluster_name}-policy-for-proxy"
  network                 = local.cluster_network
  direction               = "INGRESS"
  source_ranges           = [ google_compute_subnetwork.proxy_subnet.ip_cidr_range ]
  target_service_accounts = [ local.cluster_serviceaccount ]

  allow {
    protocol = "tcp"
    ports    = ["${local.redis_port}"]
  }
}

resource "google_compute_region_health_check" "redis_health_check" {

  project = local.gcp_project
  region  = local.worker_location
  name    = "${local.cluster_name}-healthcheck"

  timeout_sec         = 1
  check_interval_sec  = 10
  healthy_threshold   = 3
  unhealthy_threshold = 3

  tcp_health_check {

    port     = local.redis_port
    request  = "PING\r\n"
    response = "+PONG\r\n"
  }

  log_config {
    enable = true
  }

  depends_on = [google_gke_hub_feature.mcs]
}

resource "google_compute_address" "internal_lb_ip" {
  project      = local.gcp_project
  region       = local.worker_location
  name         = "${local.cluster_name}-internal-ip"
  subnetwork   = local.cluster_subnetwork
  address_type = "INTERNAL"
  purpose      = "SHARED_LOADBALANCER_VIP"
}

resource "google_compute_region_backend_service" "redis" {

  project               = local.gcp_project
  region                = local.worker_location
  name                  = "${local.cluster_name}-backend-svc"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.redis_health_check.id]
  // TODO session_affinity      = "CLIENT_IP"

  dynamic "backend" {
    for_each = toset(var.neg_zone_suffices)
    content {
      group                        = "projects/${local.gcp_project}/zones/${local.worker_location}-${backend.value}/networkEndpointGroups/${local.neg_name}"
      balancing_mode               = "CONNECTION"
      max_connections_per_endpoint = 100
      capacity_scaler              = 1.0
    }
  }
}

resource "google_compute_region_target_tcp_proxy" "redis_target_proxy" {
  project         = local.gcp_project
  region          = local.worker_location
  name            = "${local.cluster_name}-target-tcp-proxy"
  backend_service = google_compute_region_backend_service.redis.id
}

resource "google_compute_forwarding_rule" "redis_forwarding_rule" {
  project               = local.gcp_project
  region                = local.worker_location
  name                  = "${local.cluster_name}-frontend"
  ip_protocol           = "TCP"
  load_balancing_scheme = google_compute_region_backend_service.redis.load_balancing_scheme
  target                = google_compute_region_target_tcp_proxy.redis_target_proxy.id
  network               = local.cluster_network
  subnetwork            = local.cluster_subnetwork
  port_range            = local.redis_port
  ip_address            = google_compute_address.internal_lb_ip.address

  depends_on = [google_compute_subnetwork.proxy_subnet]
}

