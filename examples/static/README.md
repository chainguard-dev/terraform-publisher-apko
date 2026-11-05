# Build a simple `static` image

This example builds a very simple `static` image with a small handful
of packages needed to run statically linked binaries.

It can be deployed by running the following commands:

```
export TF_VAR_target_repository=ghcr.io/${USER}
# The identity cosign signs as, which the example verifies the signatures
# and attestations against.
export TF_VAR_oidc_issuer=https://accounts.google.com
export TF_VAR_oidc_subject=${USER}@example.com
terraform init
terraform apply -auto-approve
```