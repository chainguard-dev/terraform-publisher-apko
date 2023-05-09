/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

output "image_ref" {
  value = cosign_sign.signature.signed_ref

  depends_on = [cosign_attest.sboms, cosign_attest.apko-configuration]
}

output "config" {
  value = data.apko_config.this.config
}

output "archs" {
  value = local.archs
}

output "arch_to_image" {
  value = {
    for k, v in apko_build.this.sboms : k => v.digest
  }

  depends_on = [cosign_attest.sboms, cosign_attest.apko-configuration]
}
