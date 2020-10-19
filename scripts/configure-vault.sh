#!/bin/sh -xe

echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' > "$HOME/.terraformrc"

wget https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl -O ~/kubectl
chmod +x ~/kubectl

while ! ~/kubectl get ns vault; do
	echo Waiting for vault namespace
	sleep 15
done

while test "$(~/kubectl -n vault get pods --selector 'app.kubernetes.io/name=vault' --output=name | wc -l)" -eq 0; do
	echo Waiting for pods in vault namespace
	sleep 15
done

~/kubectl -n vault wait "$(~/kubectl -n vault get pods --selector 'app.kubernetes.io/name=vault' --output=name)" --for=condition=Ready --timeout=-1s

cd vault || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform apply --auto-approve
terraform plan --detailed-exitcode
