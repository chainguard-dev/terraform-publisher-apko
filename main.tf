/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

terraform {
  required_providers {
    cosign = {
      source = "chainguard-dev/cosign"
    }
    apko = {
      source = "chainguard-dev/apko"
    }
  }
}

data "apko_config" "this" {
  config_contents = var.config
}

resource "apko_build" "this" {
  repo   = var.target_repository
  config = data.apko_config.this.config
}

resource "cosign_sign" "signature" {
  image = apko_build.this.image_ref
}

locals {
  archs = toset(concat(data.apko_config.this.config.archs, length(data.apko_config.this.config.archs) > 1 ? ["index"] : []))
}

# Create SBOM attestations for each architecture.
resource "cosign_attest" "sboms" {
  for_each = local.archs

  image          = apko_build.this.sboms[each.key].digest
  predicate_type = apko_build.this.sboms[each.key].predicate_type
  predicate      = apko_build.this.sboms[each.key].predicate
}

# Create attestations for each architecture holding the "locked"
# configuration used to perform the build.
resource "cosign_attest" "apko-configuration" {
  for_each = local.archs

  image          = apko_build.this.sboms[each.key].digest
  predicate_type = "https://apko.dev/image-configuration"
  predicate      = jsonencode(data.apko_config.this.config)

  # Avoid racing with SBOMS to publish attestations.
  depends_on = [cosign_attest.sboms]
}
