terraform {
  required_providers {
    ko = {
      source = "chainguard-dev/ko"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project_id
}

variable "project_id" {
  type        = string
  description = "The project that will host the prober."
}

module "prober" {
  source = "./../../"

  name       = "basic-example"
  project_id = var.project_id

  importpath  = "github.com/chainguard-dev/terraform-google-prober/examples/basic"
  working_dir = path.module
}
