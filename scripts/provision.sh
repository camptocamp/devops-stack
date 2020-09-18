#!/bin/sh

cd terraform
terraform init -upgrade
terraform workspace select $CLUSTER_NAME || terraform workspace new $CLUSTER_NAME
terraform init -upgrade
terraform apply --auto-approve
terraform plan --detailed-exitcode

# Create values.yaml for ArgoCD app of apps
terraform show --json > terraform.tfstate.json
cat << EOF > ../values.yaml
---
  spec:
    source:
      repoURL: $CI_PROJECT_URL
      targetRevision: $CLUSTER_NAME
EOF
