# Multi-Region Prober

This example deploys a prober to multiple regions behind GCLB, which expects a
custom environment variable to be set, and will intermittently fail probers.

It can be deployed by running the following commands:

```bash
# Replace this gcloud command with the project you with to deploy the prober.
export TF_VAR_project_id=$(gcloud config list --format 'value(core.project)')
export KO_DOCKER_REPO=gcr.io/${TF_VAR_project_id}

# The domain on which to host the probers (see the note below).
export TF_VAR_domain=...

terraform init

terraform plan -out=plan.out

terraform apply "plan.out"
```

> NOTE: After this example is deployed, you must configure the name servers for
`${TF_VAR_domain}` to point to the appropriate name servers for the provisioned
DNS zone.

This prober **_WILL_** fail 100% of the time when first deployed until two slow
processes complete:

1. Name Servers have been set up, and (after that)
2. TLS certificates have been provisioned.

Once the above is complete, the prober is configured to fail ~5% of probes
by default:

```go
// This will cause us to fail roughly 5% of probes!
if num := rand.Intn(100); num < 5 {
    return fmt.Errorf("failing because we got %d", num)
}
return nil
```

## Cleanup

To clean up just run:

```bash
terraform apply -destroy -auto-approve
```
