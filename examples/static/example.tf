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

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

module "image" {
  source  = "../.."

  target_repository = var.target_repository
  config = file("${path.module}/static.yaml")
}

data "cosign_verify" "image-signature" {
  image = module.image.image_ref

  policy = jsonencode({
    apiVersion = "policy.sigstore.dev/v1beta1"
    kind       = "ClusterImagePolicy"
    metadata = {
      name = "signed"
    }
    spec = {
      images = [{
        glob = module.image.image_ref
      }]
      authorities = [{
        keyless = {
          url = "https://fulcio.sigstore.dev"
          identities = [{
            issuer  = "https://token.actions.githubusercontent.com"
            subject = "https://github.com/mattmoor/terraform-publisher-apko/.github/workflows/test.yaml@refs/heads/main"
          }]
        }
        ctlog = {
          url = "https://rekor.sigstore.dev"
        }
      }]
    }
  })
}

// TODO(mattmoor): Check the SBOM attestation as well.
