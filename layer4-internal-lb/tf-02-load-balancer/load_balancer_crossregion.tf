
resource "google_compute_firewall" "allow_proxy_to_backends" {
  project                 = local.gcp_project
  name                    = "${local.cluster_name}-policy-for-proxy"
  network                 = local.cluster_network
  direction               = "INGRESS"
  source_ranges           = [google_compute_subnetwork.proxy_subnet_xreg.ip_cidr_range]
  target_service_accounts = [local.cluster_serviceaccount]

  allow {
    protocol = "tcp"
    ports    = ["${local.redis_port}"]
  }
}

resource "google_compute_health_check" "redis_health_check_gbl" {

  project = local.gcp_project
  name    = "${local.cluster_name}-healthcheck-gbl"

  timeout_sec         = 1
  check_interval_sec  = 10
  healthy_threshold   = 3
  unhealthy_threshold = 3

  tcp_health_check {
    port_specification = "USE_FIXED_PORT"
    port               = local.redis_port
    request            = "PING\r\n"
    response           = "+PONG\r\n"
  }

  log_config {
    enable = true
  }

  depends_on = [google_gke_hub_feature.mcs]
}

resource "google_compute_backend_service" "redis_backend_gbl" {

  project               = local.gcp_project
  name                  = "${local.cluster_name}-backend-gbl"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.redis_health_check_gbl.id]
  session_affinity      = "CLIENT_IP" # not required, but a good idea for something like redis

  # in a nutshell, this is the "interesting" part of this exploration
  # re-using the kubernetes managed NEGs from our clusters' services
  dynamic "backend" {
    for_each = toset(var.combined_neg_zones)
    content {
      group                        = backend.value
      balancing_mode               = "CONNECTION"
      max_connections_per_endpoint = 100
      capacity_scaler              = 1.0
    }
  }
}

resource "google_compute_target_tcp_proxy" "redis_target_proxy_gbl" {
  project         = local.gcp_project
  name            = "${local.cluster_name}-target-proxy-gbl"
  backend_service = google_compute_backend_service.redis_backend_gbl.id
}


#### The following arent global, but are cross-regional resources that have a home region 

resource "google_compute_subnetwork" "proxy_subnet_xreg" {
  project       = local.gcp_project
  region        = local.ilb_frontend_location
  name          = "${local.cluster_name}-proxy-subnet-xreg"
  network       = local.cluster_network
  ip_cidr_range = "10.4.0.0/24" # TODO figure out a way to get an open CIDR, possibly stop using default
  role          = "ACTIVE"
  purpose       = "GLOBAL_MANAGED_PROXY"
}

resource "google_compute_address" "internal_lb_ip_xreg" {
  project      = local.gcp_project
  region       = local.ilb_frontend_location
  name         = "${local.cluster_name}-internal-ip-xreg"
  subnetwork   = local.cluster_subnetwork
  address_type = "INTERNAL"
  purpose      = "SHARED_LOADBALANCER_VIP"
}

resource "google_compute_global_forwarding_rule" "redis_forwarding_rule_xreg" {
  project               = local.gcp_project
  name                  = "${local.cluster_name}-frontend-xreg"
  target                = google_compute_target_tcp_proxy.redis_target_proxy_gbl.id
  port_range            = local.redis_port
  load_balancing_scheme = google_compute_backend_service.redis_backend_gbl.load_balancing_scheme
  ip_address            = google_compute_address.internal_lb_ip_xreg.address
  ip_protocol           = "TCP"

  depends_on = [google_compute_subnetwork.proxy_subnet_xreg]
}
