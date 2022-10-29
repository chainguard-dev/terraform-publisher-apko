variable "name" {
  description = "Name to prefix to created resources."
}

variable "project_id" {
  type        = string
  description = "The project that will host the prober."
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
