#!/bin/sh

set -e

export TF_WORKSPACE="$CLUSTER_NAME"

TF_ROOT="${TF_ROOT:-terraform}"

cd "$TF_ROOT" || exit
terraform init
terraform apply --auto-approve
terraform plan --detailed-exitcode
terraform output -json > outputs.json
cd - || exit
