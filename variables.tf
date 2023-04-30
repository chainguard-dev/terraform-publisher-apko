/*
Copyright 2023 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

variable "config" {
  description = "The apko configuration file to build and publish."
}
