#!/bin/sh -xe

cd terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform apply --auto-approve -target module.cluster.null_resource.wait_for_vault
terraform apply --auto-approve
terraform plan --detailed-exitcode
cd - || exit
