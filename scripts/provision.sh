#!/bin/sh -xe

export TF_WORKSPACE="$CLUSTER_NAME"

cd terraform || exit
terraform init -upgrade
terraform apply --auto-approve
terraform plan --detailed-exitcode
cd - || exit
