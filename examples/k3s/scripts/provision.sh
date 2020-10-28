#!/bin/sh -xe

mkdir -p ".terraform.d/plugin-cache"
echo plugin_cache_dir = \""$PWD/.terraform.d/plugin-cache"\" > "$HOME/.terraformrc"

# Terraform helm provider requires this file to be present
mkdir "$HOME/.kube"
touch "$HOME/.kube/config"

mkdir -p bin
export PATH="$PWD/bin:$PATH"

if ! test -x bin/kubectl; then
	wget https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl -O bin/kubectl
	chmod +x bin/kubectl
fi

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
