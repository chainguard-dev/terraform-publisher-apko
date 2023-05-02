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

resource "apko_build" "this" {
  repo   = var.target_repository
  config = var.config
}

resource "cosign_sign" "signature" {
  image = apko_build.this.image_ref
}

# data "apko_config" "this" {
#   config = var.config
# }

# resource "cosign_attest" "sboms" {
#   for_each = toset(concat(data.apko_config.this.data.archs, ["index"]))

#   image          = apko_build.this.sboms[each.key].digest
#   predicate_type = "https://spdx.dev/Document"
#   predicate      = apko_build.this.sboms[each.key].sbom
# }
