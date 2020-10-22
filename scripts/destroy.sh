#!/bin/sh -xe

if test -x "$DISTRIBUTION_DIR/scripts/destroy-before-script.sh" ; then
	"$DISTRIBUTION_DIR/scripts/destroy-before-script.sh"
fi

cd "$TERRAFORM_DIR" || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform destroy --auto-approve
if [ "$CLUSTER_NAME" != "default" ]; then
	terraform workspace select default
	terraform workspace delete "$CLUSTER_NAME"
fi
cd -

if test -x "$DISTRIBUTION_DIR/scripts/destroy-after-script.sh" ; then
	"$DISTRIBUTION_DIR/scripts/destroy-after-script.sh"
fi
