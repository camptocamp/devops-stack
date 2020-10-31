#!/bin/sh -xe

# Terraform helm provider requires this file to be present
test -d "$HOME/.kube" || mkdir "$HOME/.kube"
test -f "$HOME/.kube/config" || touch "$HOME/.kube/config"

cd terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
for resource in $(terraform state list|grep kubernetes_manifest); do
	terraform state rm "$resource"
done
for resource in $(terraform state list|grep helm_release); do
	terraform state rm "$resource"
done
terraform destroy --auto-approve
if [ "$CLUSTER_NAME" != "default" ]; then
	terraform workspace select default
	terraform workspace delete "$CLUSTER_NAME"
fi
cd - || exit
