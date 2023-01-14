terraform {
  required_providers {
    ko = {
      source = "ko-build/ko"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project_id
}

variable "project_id" {
  type        = string
  description = "The project that will host the prober."
}

variable "domain" {
  type        = string
  description = "The domain to put the probers behind."
}

resource "google_dns_managed_zone" "prober-zone" {
  project     = var.project_id
  name        = "complex-example-prober"
  dns_name    = "${var.domain}."
  description = "This is the DNS zone for the complex example prober."
}

module "prober" {
  source  = "chainguard-dev/prober/google"
  version = "v0.1.2"

  name       = "complex-example"
  project_id = var.project_id

  importpath  = "github.com/chainguard-dev/terraform-google-prober/examples/complex"
  working_dir = path.module

  # Deploy to three regions behind GCLB with a Google-managed
  # TLS certificate under the provided domain.
  locations = [
    "us-east1",
    "us-central1",
    "us-west1",
  ]
  domain   = var.domain
  dns_zone = google_dns_managed_zone.prober-zone.name

  env = {
    "FOO" : "bar"
  }
}
