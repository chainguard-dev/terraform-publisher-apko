terraform {
  required_providers {
    apko   = { source = "chainguard-dev/apko" }
    cosign = { source = "chainguard-dev/cosign" }
  }
}

module "test_image" {
  source = "../"

  target_repository = var.target_repository
  config            = file("${path.module}/apko-config.yaml")
  
  default_annotations = {
    "org.opencontainers.image.title"       = "Test Image"
    "org.opencontainers.image.description" = "Test image for provenance verification"
    "org.opencontainers.image.version"     = "v1.0.0"
  }

  extra_packages = []
  
  check_sbom = true
  skip_attest = false
  spdx_image = "ghcr.io/spdx/tools-golang:latest"
}