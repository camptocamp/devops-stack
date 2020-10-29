#!/bin/sh -xe

# Terraform helm provider requires this file to be present
test -d "$HOME/.kube" || mkdir "$HOME/.kube"
test -f "$HOME/.kube/config" || touch "$HOME/.kube/config"

cd terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform apply --auto-approve -target module.cluster.module.cluster -target module.cluster.helm_release.argocd
terraform apply --auto-approve -target module.cluster.kubernetes_manifest.app_of_apps
terraform apply --auto-approve -target module.cluster.null_resource.wait_for_vault
terraform apply --auto-approve
terraform plan --detailed-exitcode
cd - || exit
