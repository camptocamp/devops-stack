#!/bin/sh -xe

# Terraform helm provider requires this file to be present
test -d "$HOME/.kube" || mkdir "$HOME/.kube"
test -f "$HOME/.kube/config" || touch "$HOME/.kube/config"

cd terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform destroy --auto-approve -target module.cluster.module.cluster
if [ "$CLUSTER_NAME" != "default" ]; then
	terraform workspace select default
	terraform workspace delete "$CLUSTER_NAME"
fi
cd - || exit
