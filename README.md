# Cloud Run-based custom probers.

This repository contains a terraform module and Go library for deploying probers
that perform custom probing logic to Google Cloud.  The module packages a custom
Go prober as a container image, deploys it to Cloud Run, and then configures an
Uptime Check to periodically hit the Cloud Run URL.

## Defining a custom prober

With the little Go library provided here, a probe can be defined with as little
code as:

```go
import (
	"context"
	"log"

	"github.com/chainguard-dev/terraform-google-prober/pkg/prober"
)

func main() {
	prober.Go(context.Background(), prober.Func(func(ctx context.Context) error {
		log.Print("Got a probe!")
		return nil
	}))
}
```

> See our [basic example](./examples/basic/).

## Deploying a custom prober

With the terraform module provided here, a probe can be deployed with a little
configuration as:

```terraform
module "prober" {
  source  = "chainguard-dev/prober/google"
  version = "v0.1.2"

  name       = "basic-example"
  project_id = var.project_id

  importpath  = "github.com/chainguard-dev/terraform-google-prober/examples/basic"
  working_dir = path.module
}
```

> See our [basic example](./examples/basic/).

## Passing additional configuration

You can pass additional configuration to your custom probes via environment
variables passed to the prober application.  These can be specified in the
prober module:

```terraform
  env = {
    "FOO" : "bar"
  }
```

> See our [complex example](./examples/complex/).

## Multi-regional probers

By default, the probers run as a single-homed Cloud Run application, which is
great for development, and virtually free, but to take advantage of the
geographic distribution of GCP Uptime Checks, we need to deploy Cloud Run
applications to multiple regions behind a Google Cloud Load Balancer
(expensive!) with a TLS-terminated domain.

This can be done by specifying the following additional configuration:
```terraform

  # Deploy to three regions behind GCLB with a Google-managed
  # TLS certificate under the provided domain.
  locations = [
    "us-east1",
    "us-central1",
    "us-west1",
  ]

  # The domain under which we will provision hostnames
  domain   = var.domain

  # The Google Cloud DNS Zone to use for directing prober hostnames to the GCLB
  # IP address.
  dns_zone = google_dns_managed_zone.prober_zone.name
```

> See our [complex example](./examples/complex/).


<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cosign"></a> [cosign](#provider\_cosign) | n/a |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_ko"></a> [ko](#provider\_ko) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cosign_sign.image](https://registry.terraform.io/providers/chainguard-dev/cosign/latest/docs/resources/sign) | resource |
| [google_cloud_run_service.probers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service) | resource |
| [google_cloud_run_service_iam_policy.noauths](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_policy) | resource |
| [google_compute_backend_service.probers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_global_address.static_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_forwarding_rule.forwarding_rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_managed_ssl_certificate.prober_cert](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) | resource |
| [google_compute_region_network_endpoint_group.neg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_endpoint_group) | resource |
| [google_compute_target_https_proxy.prober](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_url_map.probers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |
| [google_dns_record_set.prober_dns](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_monitoring_uptime_check_config.global_uptime_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_uptime_check_config) | resource |
| [google_monitoring_uptime_check_config.regional_uptime_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_uptime_check_config) | resource |
| [ko_build.image](https://registry.terraform.io/providers/ko-build/ko/latest/docs/resources/build) | resource |
| [random_password.secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [cosign_verify.base-image](https://registry.terraform.io/providers/chainguard-dev/cosign/latest/docs/data-sources/verify) | data source |
| [google_iam_policy.noauth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_zone"></a> [dns\_zone](#input\_dns\_zone) | The managed DNS zone in which to create prober record sets (required for multiple locations). | `string` | `""` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain of the environment to probe (required for multiple locations). | `string` | `""` | no |
| <a name="input_env"></a> [env](#input\_env) | A map of custom environment variables (e.g. key=value) | `map` | `{}` | no |
| <a name="input_importpath"></a> [importpath](#input\_importpath) | The import path that contains the prober application. | `string` | n/a | yes |
| <a name="input_locations"></a> [locations](#input\_locations) | Where to run the Cloud Run services. | `list(string)` | <pre>[<br>  "us-central1"<br>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name to prefix to created resources. | `any` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project that will host the prober. | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | Container repository to publish images to. | `string` | `""` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The email address of the service account to run the service as. | `string` | n/a | yes |
| <a name="input_working_dir"></a> [working\_dir](#input\_working\_dir) | The working directory that contains the importpath. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_uptime_check"></a> [uptime\_check](#output\_uptime\_check) | n/a |
| <a name="output_uptime_check_name"></a> [uptime\_check\_name](#output\_uptime\_check\_name) | n/a |
<!-- END_TF_DOCS -->
