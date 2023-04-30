/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

output "image_ref" {
  value = cosign_sign.signature.signed_ref
}
