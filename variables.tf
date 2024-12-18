/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

variable "target_repository" {
  type        = string
  description = "The docker repo into which the image and attestations should be published."
}

variable "extra_packages" {
  type        = list(string)
  default     = []
  description = "Additional packages to install into this image."
}

variable "config" {
  type        = string
  description = "The apko configuration file contents to build and publish."
}

variable "default_annotations" {
  type        = map(string)
  default     = {}
  description = "Default annotations to apply to this image."
}

variable "check_sbom" {
  type        = bool
  default     = true
  description = "Whether to run the NTIA conformance checker on the SBOMs we are attesting."
}

variable "spdx_image" {
  type        = string
  default     = "ghcr.io/wolfi-dev/spdx-tools:latest"
  description = "The SPDX checker image to use to validate SBOMs."
}

variable "skip_attest" {
  type        = bool
  description = "If true, skip the attestations step. This is NOT RECOMMENDED, and should only be used when attestations may be too big for Rekor."
  default     = false
}
