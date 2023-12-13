/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

variable "extra_packages" {
  type        = list(string)
  default     = []
  description = "Additional packages to install into this image."
}

variable "config" {
  description = "The apko configuration file to build and publish."
}

variable "default_annotations" {
  type        = map(string)
  default     = {}
  description = "Default annotations to apply to this image."
}

variable "check_sbom" {
  default     = true
  description = "Whether to run the NTIA conformance checker on the SBOMs we are attesting."
}

variable "sbom_checker" {
  default     = "cgr.dev/chainguard/ntia-conformance-checker:latest"
  description = "The NTIA conformance checker image to use to validate SBOMs."
}
