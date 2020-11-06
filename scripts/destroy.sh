#!/bin/sh -xe

export TF_WORKSPACE="$CLUSTER_NAME"

cd terraform || exit
terraform init -upgrade
terraform destroy --auto-approve
if [ "$CLUSTER_NAME" != "default" ]; then
	terraform workspace select default
	terraform workspace delete "$CLUSTER_NAME"
fi
cd - || exit
