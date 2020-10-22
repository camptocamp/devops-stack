#!/bin/sh -xe

if test -x "$DISTRIBUTION_DIR/scripts/provision-before-script.sh"; then
	"$DISTRIBUTION_DIR/scripts/provision-before-script.sh"
fi

cd "$TERRAFORM_DIR" || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform apply --auto-approve
terraform plan --detailed-exitcode
cd -

if test -x "$DISTRIBUTION_DIR/scripts/provision-after-script.sh"; then
	"$DISTRIBUTION_DIR/scripts/provision-after-script.sh"
fi
