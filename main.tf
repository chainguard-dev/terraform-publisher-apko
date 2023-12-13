/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

terraform {
  required_providers {
    apko   = { source = "chainguard-dev/apko" }
    cosign = { source = "chainguard-dev/cosign" }
    oci    = { source = "chainguard-dev/oci" }
  }
}

data "apko_config" "this" {
  config_contents     = var.config
  extra_packages      = var.extra_packages
  default_annotations = var.default_annotations
}

resource "apko_build" "this" {
  repo   = var.target_repository
  config = data.apko_config.this.config
}

# NOTE: The Diff API vulnerability scan generator depends on signature push events to happen on daily basis for every rebuilt image.
resource "cosign_sign" "signature" {
  image = apko_build.this.image_ref

  # Only keep the latest signature. We use these to ensure we regularly rebuild.
  conflict = "REPLACE"
}

locals {
  archs = toset(concat(["index"], data.apko_config.this.config.archs))
}

data "oci_exec_test" "check-sbom" {
  for_each = var.check_sbom ? local.archs : []
  digest   = apko_build.this.sboms[each.key].digest

  # Run the supplied NTIA checker over the SBOM files mounted into the checker image in a readonly mode.
  # We run as root to avoid permission issues reading the SBOM as the default nonroot user.
  script = "docker run --rm --user 0 -v ${apko_build.this.sboms[each.key].predicate_path}:/sbom.json:ro ${var.sbom_checker} -v --file /sbom.json"
}

resource "cosign_attest" "this" {
  for_each = local.archs

  depends_on = [data.oci_exec_test.check-sbom]

  image = apko_build.this.sboms[each.key].digest

  # Do not re-attest things that have not changed.
  conflict = "SKIPSAME"

  # Create SBOM attestations for each architecture.
  predicates {
    type = apko_build.this.sboms[each.key].predicate_type
    file {
      path   = apko_build.this.sboms[each.key].predicate_path
      sha256 = apko_build.this.sboms[each.key].predicate_sha256
    }
  }

  # Create attestations for each architecture holding the "locked"
  # configuration used to perform the build.
  predicates {
    type = "https://apko.dev/image-configuration"
    json = jsonencode(data.apko_config.this.config)
  }

  # Create attestations for each architecture holding the SLSA
  # provenance of the build.
  predicates {
    type = "https://slsa.dev/provenance/v1"
    json = jsonencode({
      buildDefinition = {
        buildType = "https://apko.dev/slsa-build-type@v1"
        # TODO(mattmoor): consider putting variables into `externalParameters`?
        # TODO(mattmoor): how do we fit into the shape of `resolvedDependencies`?

        # Use internal parameters to document the package resolution.
        internalParameters = {
          for k in data.apko_config.this.config.contents.packages : split("=", k)[0] => split("=", k)[1]
        }

        # TODO(mattmoor): Use an extension to encode the fully resolved apko configuration.
      }
      runDetails = {
        builder = {
          id = "https://github.com/chainguard-dev/terraform-provider-apko"
          version = {
            # TODO(mattmoor): How do we get the version of tf-apko?
          }
        }
        metadata = {
          invocationId = apko_build.this.id
        }
      }
    })
  }
}
