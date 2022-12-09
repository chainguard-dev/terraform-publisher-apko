# Single-Region Prober

This example deploys a prober to a single region (`us-central1`), which simply
logs the request and succeeds.

It can be deployed by running the following commands:

```bash
# Replace this gcloud command with the project you with to deploy the prober.
export TF_VAR_project_id=$(gcloud config list --format 'value(core.project)')
export KO_DOCKER_REPO=gcr.io/${TF_VAR_project_id}

terraform init

terraform plan -out=plan.out

terraform apply "plan.out"
```

## Cleanup

To clean up just run:

```bash
terraform apply -destroy -auto-approve
```
