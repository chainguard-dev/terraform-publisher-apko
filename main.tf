/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

terraform {
  required_providers {
    apko   = { source = "chainguard-dev/apko", version = ">= 0.29.10" }
    cosign = { source = "chainguard-dev/cosign" }
  }
}

data "apko_config" "this" {
  config_contents     = var.config
  extra_packages      = var.extra_packages
  default_annotations = var.default_annotations
}

resource "apko_build" "this" {
  repo    = var.target_repository
  config  = data.apko_config.this.config
  configs = data.apko_config.this.configs
}

# NOTE: The Diff API vulnerability scan generator depends on signature push events to happen on daily basis for every rebuilt image.
resource "cosign_sign" "signature" {
  image = apko_build.this.image_ref

  # Only keep the latest signature. We use these to ensure we regularly rebuild.
  conflict = "REPLACE"
}

locals { archs = toset(concat(["index"], try(jsondecode(var.config).archs, []))) }

resource "null_resource" "check-sbom-spdx" {
  for_each = var.check_sbom ? local.archs : []

  triggers = {
    digest = apko_build.this.sboms[each.key].digest
  }

  provisioner "local-exec" {
    # Run the supplied SPDX checker over the SBOM file mounted into the image in a readonly mode.
    # We run as root to avoid permission issues reading the SBOM as the default nonroot user.
    command = <<EOF
  docker run --rm --user 0 \
      -v ${apko_build.this.sboms[each.key].predicate_path}:/sbom.json:ro \
      ${var.spdx_image} \
      Verify /sbom.json
  EOF
  }
}

resource "cosign_attest" "this" {
  for_each = var.skip_attest ? [] : local.archs

  depends_on = [null_resource.check-sbom-spdx]

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
    json = jsonencode(data.apko_config.this.configs[each.key].config)
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
          for k in data.apko_config.this.configs[each.key].config.contents.packages : split("=", k)[0] => split("=", k)[1]
        }

        # TODO(mattmoor): Use an extension to encode the fully resolved apko configuration.
      }
      runDetails = {
        builder = {
          id = "https://github.com/chainguard-dev/terraform-provider-apko"
          version = {
            apko                    = provider::apko::version().apko_version
            terraform-provider-apko = provider::apko::version().provider_version
          }
        }
        metadata = {
          invocationId = apko_build.this.id
        }
      }
    })
  }
}
