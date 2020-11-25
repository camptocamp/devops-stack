#!/bin/sh

set -e

export TF_WORKSPACE="$CLUSTER_NAME"

cd terraform || exit
terraform init -upgrade

# FIXME: Somehow Terraform's Helm provider does not do it even though
# I specified `dependency_update = true`
helm dependency update "$(jq -r '.Modules[]|select(.Key == "cluster").Dir + "/../../argocd/argocd/"' .terraform/modules/modules.json)"

terraform apply --auto-approve
terraform plan --detailed-exitcode
terraform output -json > outputs.json
cd - || exit
