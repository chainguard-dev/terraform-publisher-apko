/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

terraform {
  required_providers {
    apko   = { source = "chainguard-dev/apko" }
    cosign = { source = "chainguard-dev/cosign" }
  }
}

data "apko_config" "this" {
  config_contents     = var.config
  extra_packages      = var.extra_packages
  default_annotations = var.default_annotations
}

data "external" "apko_version" {
  program = ["sh", "-c", "apko version --json 2>/dev/null || echo '{\"version\":\"unknown\"}'"]
}

# Capture terraform start time early in execution
data "external" "terraform_start_time" {
  program = ["sh", "-c", "echo '{\"timestamp\":\"'$(date -Iseconds)'\"}'"]
}

resource "apko_build" "this" {
  repo    = var.target_repository
  config  = data.apko_config.this.config
  configs = data.apko_config.this.configs

  lifecycle {
    postcondition {
      condition     = length(self.image_ref) > 0
      error_message = "apko_build failed to produce a valid image_ref"
    }
  }
}

# NOTE: The Diff API vulnerability scan generator depends on signature push events to happen on daily basis for every rebuilt image.
resource "cosign_sign" "signature" {
  image = apko_build.this.image_ref

  # Only keep the latest signature. We use these to ensure we regularly rebuild.
  conflict = "REPLACE"
}

locals { 
  archs = toset(concat(["index"], data.apko_config.this.config.archs))
  
  # Provenance metadata variables - derived from apko config and build context
  main_package = try(split("/", var.target_repository)[length(split("/", var.target_repository)) - 1], "unknown")
  image_authors = "Chainguard Team https://www.chainguard.dev/"
  image_base_digest = try(apko_build.this.sboms["index"].digest, apko_build.this.image_ref)
  image_source = try(data.apko_config.this.config.annotations["org.opencontainers.image.source"], "https://github.com/chainguard-images/images")
  image_url = "https://images.chainguard.dev"
  image_vendor = "Chainguard"
  default_repositories = try(data.apko_config.this.config.contents.repositories, ["https://packages.wolfi.dev/os"])
  default_entrypoint_command = try(data.apko_config.this.config.entrypoint.command, "/bin/sh")
  default_layering_budget = try(data.apko_config.this.config.layering.budget, 10)
  default_layering_strategy = try(data.apko_config.this.config.layering.strategy, "origin")
  
  # Cloud instance metadata - these would be populated by the actual build environment
  ## TODO[antitree] in the future we can get more specific about GHA and the details but we're skipping it for now.
  cloud_instance_id = ""
  cloud_region = ""
  cloud_type = ""
  
  # Builder version information - dynamically extracted from apko binary
  apko_version = try(data.external.apko_version.result.version, "unknown")
  
  # Build timing metadata - captured from terraform execution
  build_started_on = data.external.terraform_start_time.result.timestamp
  build_finished_on = timestamp()
}

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
        buildType = "https://chainguard.dev/buildtypes/apko/v1"
        externalParameters = {
          image-configuration = {
            accounts = {
              groups = try([
                for group in data.apko_config.this.configs[each.key].config.accounts.groups : {
                  gid       = group.gid
                  groupname = group.groupname
                }
              ], [])
              run-as = try(tostring(data.apko_config.this.configs[each.key].config.accounts.run-as), "0")
              users = try([
                for user in data.apko_config.this.configs[each.key].config.accounts.users : {
                  gid      = user.gid
                  homedir  = user.homedir
                  uid      = user.uid
                  username = user.username
                }
              ], [])
            }
            annotations = merge(
              try(data.apko_config.this.configs[each.key].config.annotations, {}),
              {
                "dev.chainguard.package.main"        = local.main_package
                "org.opencontainers.image.authors"   = local.image_authors
                "org.opencontainers.image.base.digest" = local.image_base_digest
                "org.opencontainers.image.source"    = local.image_source
                "org.opencontainers.image.url"       = local.image_url
                "org.opencontainers.image.vendor"    = local.image_vendor
              }
            )
            archs = data.apko_config.this.configs[each.key].config.archs
            contents = {
              packages = data.apko_config.this.configs[each.key].config.contents.packages
              repositories = try(data.apko_config.this.configs[each.key].config.contents.repositories, local.default_repositories)
            }
            entrypoint = {
              command = try(data.apko_config.this.configs[each.key].config.entrypoint.command, local.default_entrypoint_command)
            }
            layering = try({
              budget   = data.apko_config.this.configs[each.key].config.layering.budget
              strategy = data.apko_config.this.configs[each.key].config.layering.strategy
            }, {
              budget   = local.default_layering_budget
              strategy = local.default_layering_strategy
            })
          }
        }
        internalParameters = {
          # TODO: We'd like to have similar information about GHA runners, but we don't have a way to get it yet.
          # cloud = {
          #   instanceId = local.cloud_instance_id
          #   region     = local.cloud_region
          #   type       = local.cloud_type
          # }
        }
      }
      runDetails = {
        builder = {
          id = "https://chainguard.dev/prod/builders/apko/v1"
          version = {
            apko = local.apko_version
          }
        }
        metadata = {
          finishedOn = local.build_finished_on
          startedOn  = local.build_started_on
          invocationId = apko_build.this.id
        }
      }
    })
  }
}
