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

resource "cosign_attest" "sboms" {
  for_each = apko_build.this.sboms

  image          = each.key
  predicate_type = "https://spdx.dev/Document"
  predicate      = each.value
}

