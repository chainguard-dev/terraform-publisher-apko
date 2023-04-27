/*
Copyright 2022 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

terraform {
  required_providers {
    cosign = {
      source = "chainguard-dev/cosign"
    }
    ko = {
      source = "ko-build/ko"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  repo = var.repository != "" ? var.repository : "gcr.io/${var.project_id}/${var.name}"
}

data "cosign_verify" "base-image" {
  image = "cgr.dev/chainguard/static:latest-glibc"

  policy = jsonencode({
    apiVersion = "policy.sigstore.dev/v1beta1"
    kind       = "ClusterImagePolicy"
    metadata = {
      name = "chainguard-images-are-signed"
    }
    spec = {
      images = [{
        glob = "cgr.dev/**"
      }]
      authorities = [{
        keyless = {
          url = "https://fulcio.sigstore.dev"
          identities = [{
            issuer  = "https://token.actions.githubusercontent.com"
            subject = "https://github.com/chainguard-images/images/.github/workflows/release.yaml@refs/heads/main"
          }]
        }
        ctlog = {
          url = "https://rekor.sigstore.dev"
        }
      }]
    }
  })
}

// Build the prober into an image we can run on Cloud Run.
resource "ko_build" "image" {
  repo        = local.repo
  base_image  = data.cosign_verify.base-image.verified_ref
  importpath  = var.importpath
  working_dir = var.working_dir
}

resource "cosign_sign" "image" {
  image = ko_build.image.image_ref
}

// Create a shared secret to have the uptime check pass to the
// Cloud Run app as an "Authorization" header to keep ~anyone
// from being able to use our prober endpoints to indirectly
// DoS our SaaS.
resource "random_password" "secret" {
  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

// Spin up a Cloud Run service to perform our custom prober logic.
resource "google_cloud_run_service" "probers" {
  for_each = toset(var.locations)

  project = var.project_id
  # Cloud Run Service accounts can be 49 characters long, so truncate var.name to 45 chars.
  name     = "${substr(var.name, 0, 45)}-prb"
  location = each.key

  template {
    spec {
      service_account_name = var.service_account
      containers {
        image = cosign_sign.image.signed_ref

        // This is a shared secret with the uptime check, which must be
        // passed in an Authorization header for the probe to do work.
        env {
          name  = "AUTHORIZATION"
          value = random_password.secret.result
        }

        dynamic "env" {
          for_each = var.env
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauths" {
  for_each = toset(var.locations)

  project  = var.project_id
  location = each.key
  service  = google_cloud_run_service.probers[each.key].name

  policy_data = data.google_iam_policy.noauth.policy_data
}

// This is the uptime check, which will send traffic to the Cloud Run
// application every few minutes (from several locations) to ensure
// things are operating as expected.
resource "google_monitoring_uptime_check_config" "regional_uptime_check" {
  count = local.use_gclb ? 0 : 1

  display_name = "${var.name}-uptime-regional"
  project      = var.project_id
  timeout      = "60s"
  period       = "300s"

  http_check {
    path         = "/"
    port         = "443"
    use_ssl      = true
    validate_ssl = true

    // Pass the shared secret as an Authorization header.
    headers = {
      "Authorization" = random_password.secret.result
    }
  }

  monitored_resource {
    labels = {
      // Strip the scheme and path off of the Cloud Run URL.
      host       = split("/", google_cloud_run_service.probers[var.locations[0]].status[0].url)[2]
      project_id = var.project_id
    }

    type = "uptime_url"
  }

  lifecycle {
    # We must create any replacement uptime checks before
    # we tear this check down.
    create_before_destroy = true
  }
}

// This is the uptime check, which will send traffic to the GCLB
// address every few minutes (from several locations) to ensure
// things are operating as expected.
resource "google_monitoring_uptime_check_config" "global_uptime_check" {
  count = local.use_gclb ? 1 : 0

  display_name = "${var.name}-uptime-global"
  project      = var.project_id
  timeout      = "60s"
  period       = "300s"

  http_check {
    path         = "/"
    port         = "443"
    use_ssl      = true
    validate_ssl = true

    // Pass the shared secret as an Authorization header.
    headers = {
      "Authorization" = random_password.secret.result
    }
  }

  monitored_resource {
    labels = {
      host       = "${var.name}-prober.${var.domain}."
      project_id = var.project_id
    }

    type = "uptime_url"
  }

  lifecycle {
    # We must create any replacement uptime checks before
    # we tear this check down.
    create_before_destroy = true
  }
}
