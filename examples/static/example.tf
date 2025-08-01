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

variable "archs" {
  description = "The architectures to build for."
  type        = list(string)
  default     = ["x86_64", "aarch64"]
}

variable "check_sbom" {
  description = "Whether to run the NTIA conformance checker and SPDX validity test on the SBOMs we are attesting."
  type        = bool
  default     = true
}

variable "verify" {
  description = "Whether to verify image signatures and attestations."
  type        = bool
  default     = true
}

provider "apko" {
  extra_repositories = ["https://packages.wolfi.dev/os"]
  extra_keyring      = ["https://packages.wolfi.dev/os/wolfi-signing.rsa.pub"]
  default_archs      = var.archs
  extra_packages     = ["wolfi-baselayout"]
}

module "image" {
  source = "../.."

  target_repository = var.target_repository
  config            = file("${path.module}/static.yaml")

  check_sbom = var.check_sbom

  # Simulate a "dev" variant
  extra_packages = ["busybox"]

  default_annotations = {
    "org.opencontainers.image.source" = "https://github.com/chainguard-dev/terraform-publisher-apko/examples/${basename(path.cwd)}"
  }
}

data "cosign_verify" "image-signatures" {
  for_each = var.verify ? module.image.archs : []
  image    = module.image.arch_to_image[each.key]

  policy = jsonencode({
    apiVersion = "policy.sigstore.dev/v1beta1"
    kind       = "ClusterImagePolicy"
    metadata = {
      name = "signed"
    }
    spec = {
      images = [{ glob = "**" }]
      authorities = [{
        keyless = {
          url = "https://fulcio.sigstore.dev"
          identities = [{
            issuer  = "https://token.actions.githubusercontent.com"
            subject = "https://github.com/chainguard-dev/terraform-publisher-apko/.github/workflows/test.yaml@refs/heads/main"
          }]
        }
        ctlog = {
          url = "https://rekor.sigstore.dev"
        }
      }]
    }
  })
}

data "cosign_verify" "sbom-attestations" {
  for_each = var.verify ? module.image.archs : []
  image    = module.image.arch_to_image[each.key]

  policy = jsonencode({
    apiVersion = "policy.sigstore.dev/v1beta1"
    kind       = "ClusterImagePolicy"
    metadata = {
      name = "sbom-attestation"
    }
    spec = {
      images = [{ glob = "**" }]
      authorities = [{
        keyless = {
          url = "https://fulcio.sigstore.dev"
          identities = [{
            issuer  = "https://token.actions.githubusercontent.com"
            subject = "https://github.com/chainguard-dev/terraform-publisher-apko/.github/workflows/test.yaml@refs/heads/main"
          }]
        }
        ctlog = {
          url = "https://rekor.sigstore.dev"
        }
        attestations = [
          {
            name          = "spdx-att"
            predicateType = "https://spdx.dev/Document"
            policy = {
              type = "cue"
              # TODO(mattmoor): Add more meaningful SBOM checks.
              data = "predicateType: \"https://spdx.dev/Document\""
            }
          },
        ]
      }]
    }
  })
}

data "cosign_verify" "config-attestations" {
  for_each = var.verify ? module.image.archs : []
  image    = module.image.arch_to_image[each.key]

  policy = jsonencode({
    apiVersion = "policy.sigstore.dev/v1beta1"
    kind       = "ClusterImagePolicy"
    metadata = {
      name = "config-attestation"
    }
    spec = {
      images = [{ glob = "**" }]
      authorities = [{
        keyless = {
          url = "https://fulcio.sigstore.dev"
          identities = [{
            issuer  = "https://token.actions.githubusercontent.com"
            subject = "https://github.com/chainguard-dev/terraform-publisher-apko/.github/workflows/test.yaml@refs/heads/main"
          }]
        }
        ctlog = {
          url = "https://rekor.sigstore.dev"
        }
        attestations = [
          {
            name          = "config-att"
            predicateType = "https://apko.dev/image-configuration"
            policy = {
              type = "cue"
              # TODO(mattmoor): Add more meaningful checks.
              data = "predicateType: \"https://apko.dev/image-configuration\""
            }
          },
        ]
      }]
    }
  })
}

output "image_ref" {
  value = module.image.image_ref
}

output "apko_version" {
  value       = provider::apko::version()
  description = "The version of the apko provider used to build this image."
}
