# Build apko images with terraform.

This repository contains a terraform module to facilitate building an image with
apko and signing the supply chain metadata with ambient credentials (e.g. github
actions workload identity).

Currently the following supply chain metadata is surfaced:
1. The images are signed by the workload,
2. The SPDX SBOM are attestated by the workload.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_apko"></a> [apko](#provider\_apko) | n/a |
| <a name="provider_cosign"></a> [cosign](#provider\_cosign) | n/a |
| <a name="provider_oci"></a> [oci](#provider\_oci) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [apko_build.this](https://registry.terraform.io/providers/chainguard-dev/apko/latest/docs/resources/build) | resource |
| [cosign_attest.this](https://registry.terraform.io/providers/chainguard-dev/cosign/latest/docs/resources/attest) | resource |
| [cosign_sign.signature](https://registry.terraform.io/providers/chainguard-dev/cosign/latest/docs/resources/sign) | resource |
| [apko_config.this](https://registry.terraform.io/providers/chainguard-dev/apko/latest/docs/data-sources/config) | data source |
| [oci_exec_test.check-sbom](https://registry.terraform.io/providers/chainguard-dev/oci/latest/docs/data-sources/exec_test) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_check_sbom"></a> [check\_sbom](#input\_check\_sbom) | Whether to run the NTIA conformance checker on the SBOMs we are attesting. | `bool` | `true` | no |
| <a name="input_config"></a> [config](#input\_config) | The apko configuration file to build and publish. | `any` | n/a | yes |
| <a name="input_default_annotations"></a> [default\_annotations](#input\_default\_annotations) | Default annotations to apply to this image. | `map(string)` | `{}` | no |
| <a name="input_extra_packages"></a> [extra\_packages](#input\_extra\_packages) | Additional packages to install into this image. | `list(string)` | `[]` | no |
| <a name="input_sbom_checker"></a> [sbom\_checker](#input\_sbom\_checker) | The NTIA conformance checker image to use to validate SBOMs. | `string` | `"cgr.dev/chainguard/ntia-conformance-checker:latest"` | no |
| <a name="input_target_repository"></a> [target\_repository](#input\_target\_repository) | The docker repo into which the image and attestations should be published. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arch_to_image"></a> [arch\_to\_image](#output\_arch\_to\_image) | n/a |
| <a name="output_archs"></a> [archs](#output\_archs) | n/a |
| <a name="output_config"></a> [config](#output\_config) | n/a |
| <a name="output_image_ref"></a> [image\_ref](#output\_image\_ref) | n/a |
<!-- END_TF_DOCS -->
