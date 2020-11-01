#!/bin/sh -xe

# Terraform helm provider requires this file to be present
test -d "$HOME/.kube" || mkdir "$HOME/.kube"
test -f "$HOME/.kube/config" || touch "$HOME/.kube/config"

cd terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform plan --detailed-exitcode
cd - || exit
