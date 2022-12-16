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
  source  = "chainguard-dev/prober/google"
  version = "v0.1.2"

  name       = "basic-example"
  project_id = var.project_id

  importpath  = "github.com/chainguard-dev/terraform-google-prober/examples/basic"
  working_dir = path.module

  env = {
    EXAMPLE_ENV = "honk"
  }
}

// Create an alert policy based on the uptime check above.
resource "google_monitoring_alert_policy" "prober_uptime" {
  project = var.project_id
  # In the absence of data, incident will auto-close in 7 days
  alert_strategy {
    auto_close = "604800s"
  }
  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.*"]
        per_series_aligner   = "ALIGN_NEXT_OLDER"
      }

      comparison = "COMPARISON_GT"
      duration   = "60s"
      filter     = format("metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.\"check_id\"=\"%s\"", module.prober.uptime_check)

      threshold_value = "1"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "${module.prober.uptime_check_name} probe failure"
  }

  display_name = "${module.prober.uptime_check_name} prober failed alert"
  enabled      = "true"

  documentation {
    content = <<-EOT
    < Add your documentation or link to a playbook here >
    EOT
  }

  depends_on = [
    module.prober
  ]
}
