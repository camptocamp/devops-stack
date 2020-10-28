#!/bin/sh -xe

# Terraform helm provider requires this file to be present
test -d "$HOME/.kube" || mkdir "$HOME/.kube"
test -f "$HOME/.kube/config" || touch "$HOME/.kube/config"

cd terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform apply --auto-approve \
	-target module.cluster.module.cluster \
	-target module.cluster.helm_release.argocd \
	-target module.cluster.module.iam_assumable_role_cert_manager \
	-target module.cluster.aws_cognito_user_pool_client.client \
	-target module.cluster.random_password.oauth2_cookie_secret
terraform apply --auto-approve -target module.cluster.kubernetes_manifest.app_of_apps
terraform apply --auto-approve -target module.cluster.null_resource.wait_for_vault
terraform apply --auto-approve
terraform plan --detailed-exitcode
cd - || exit
