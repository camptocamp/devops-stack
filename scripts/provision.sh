#!/bin/sh -xe

cd terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform apply --auto-approve
terraform plan --detailed-exitcode

# Create values.yaml for ArgoCD app of apps
terraform show --json > terraform.tfstate.json
cat << EOF > ../values.yaml
---
spec:
  source:
    repoURL: $REPO_URL
    targetRevision: $CLUSTER_NAME
EOF
