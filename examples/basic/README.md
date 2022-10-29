# Single-Region Prober

This example deploys a prober to a single region (`us-central1`), which simply
logs the request and succeeds.

It can be deployed by running the following commands:
```bash
# Replace this gcloud command with the project you with to deploy the prober.
export TF_VAR_project_id=$(gcloud config list --format 'value(core.project)')
export KO_DOCKER_REPO=gcr.io/${TF_VAR_project_id}

terraform apply
```
