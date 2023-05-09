/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

output "image_ref" {
  value = cosign_sign.signature.signed_ref

  depends_on = [cosign_attest.sboms]
}

output "config" {
  value = data.apko_config.this.config
}

output "archs" {
  value = toset(concat(data.apko_config.this.config.archs, length(data.apko_config.this.config.archs) > 1 ? ["index"] : []))
}

output "arch_to_image" {
  value = {
    for k, v in apko_build.this.sboms : k => v.digest
  }

  depends_on = [cosign_attest.sboms]
}
