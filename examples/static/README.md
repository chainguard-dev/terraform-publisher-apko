# Build a simple `static` image

This example builds a very simple `static` image with a small handful
of packages needed to run statically linked binaries.

It can be deployed by running the following commands:

```
export TF_VAR_target_repository=ghcr.io/${USER}
terraform init
terraform apply -auto-approve
```
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cosign"></a> [cosign](#provider\_cosign) | 0.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_image"></a> [image](#module\_image) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [cosign_verify.config-attestations](https://registry.terraform.io/providers/chainguard-dev/cosign/latest/docs/data-sources/verify) | data source |
| [cosign_verify.image-signatures](https://registry.terraform.io/providers/chainguard-dev/cosign/latest/docs/data-sources/verify) | data source |
| [cosign_verify.sbom-attestations](https://registry.terraform.io/providers/chainguard-dev/cosign/latest/docs/data-sources/verify) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_archs"></a> [archs](#input\_archs) | The architectures to build for. | `list(string)` | <pre>[<br/>  "x86_64",<br/>  "aarch64"<br/>]</pre> | no |
| <a name="input_check_sbom"></a> [check\_sbom](#input\_check\_sbom) | Whether to run the NTIA conformance checker and SPDX validity test on the SBOMs we are attesting. | `bool` | `true` | no |
| <a name="input_target_repository"></a> [target\_repository](#input\_target\_repository) | The docker repo into which the image and attestations should be published. | `any` | n/a | yes |
| <a name="input_verify"></a> [verify](#input\_verify) | Whether to verify image signatures and attestations. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apko_version"></a> [apko\_version](#output\_apko\_version) | The version of the apko provider used to build this image. |
| <a name="output_image_ref"></a> [image\_ref](#output\_image\_ref) | n/a |
<!-- END_TF_DOCS -->