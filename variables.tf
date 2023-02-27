/*
Copyright 2022 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

variable "name" {
  description = "Name to prefix to created resources."
}

variable "project_id" {
  type        = string
  description = "The project that will host the prober."
}

variable "base_image" {
  type        = string
  default     = "cgr.dev/chainguard/static:latest-glibc"
  description = "The base image that will be used to build the container image."
}

variable "repository" {
  type        = string
  default     = ""
  description = "Container repository to publish images to."
}

variable "service_account" {
  type        = string
  description = "The email address of the service account to run the service as."
}

variable "importpath" {
  type        = string
  description = "The import path that contains the prober application."
}

variable "working_dir" {
  type        = string
  description = "The working directory that contains the importpath."
}

variable "locations" {
  type        = list(string)
  default     = ["us-central1"]
  description = "Where to run the Cloud Run services."
}

variable "dns_zone" {
  type        = string
  default     = ""
  description = "The managed DNS zone in which to create prober record sets (required for multiple locations)."
}

variable "domain" {
  type        = string
  default     = ""
  description = "The domain of the environment to probe (required for multiple locations)."
}

variable "env" {
  default     = {}
  description = "A map of custom environment variables (e.g. key=value)"
}
