/*
Copyright 2022 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

locals {
  # GCLB is expensive, so we only provision one when we have to put multiple
  # Cloud Run locations behind one.
  use_gclb = length(var.locations) > 1
}

resource "google_compute_global_address" "static_ip" {
  count = local.use_gclb ? 1 : 0

  project = var.project_id
  name    = "${var.name}-prober"
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  count = local.use_gclb ? 1 : 0

  project               = var.project_id
  name                  = "${var.name}-prober"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = 443
  ip_address            = google_compute_global_address.static_ip[0].id
  target                = google_compute_target_https_proxy.prober[0].id
}

resource "google_dns_record_set" "prober_dns" {
  count = local.use_gclb ? 1 : 0

  project      = var.project_id
  name         = "${var.name}-prober.${var.domain}."
  managed_zone = var.dns_zone
  type         = "A"
  ttl          = 60

  rrdatas = [
    google_compute_global_address.static_ip[0].address
  ]
}

resource "google_compute_managed_ssl_certificate" "prober_cert" {
  count = local.use_gclb ? 1 : 0

  name = "${var.name}-prober"

  managed {
    domains = [google_dns_record_set.prober_dns[0].name]
  }
}

resource "google_compute_target_https_proxy" "prober" {
  count = local.use_gclb ? 1 : 0

  project = var.project_id
  name    = "${var.name}-prober"
  url_map = google_compute_url_map.probers[0].id

  ssl_certificates = [google_compute_managed_ssl_certificate.prober_cert[0].id]
}

resource "google_compute_url_map" "probers" {
  count = local.use_gclb ? 1 : 0

  project         = var.project_id
  name            = "${var.name}-probers"
  default_service = google_compute_backend_service.probers[0].id
}

// Create a regional network endpoint group (NEG) for each regional Cloud Run service.
resource "google_compute_region_network_endpoint_group" "neg" {
  for_each = toset(local.use_gclb ? var.locations : [])

  name                  = "${var.name}-probers"
  network_endpoint_type = "SERVERLESS"
  region                = each.key
  cloud_run {
    service = google_cloud_run_service.probers[each.key].name
  }
}

resource "google_compute_backend_service" "probers" {
  count = local.use_gclb ? 1 : 0

  project = var.project_id
  name    = "${var.name}-probers"

  dynamic "backend" {
    for_each = toset(var.locations)
    content {
      group = google_compute_region_network_endpoint_group.neg[backend.key]["id"]
    }
  }
}
