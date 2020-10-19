#!/bin/sh -xe

if test -x distributions/"$DISTRIBUTION"/scripts/destroy-before-script.sh ; then
	distributions/"$DISTRIBUTION"/scripts/destroy-before-script.sh
fi

cd distributions/"$DISTRIBUTION"/terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform destroy --auto-approve
if [ "$CLUSTER_NAME" != "default" ]; then
	terraform workspace select default
	terraform workspace delete "$CLUSTER_NAME"
fi
cd -

if test -x distributions/"$DISTRIBUTION"/scripts/destroy-after-script.sh ; then
	distributions/"$DISTRIBUTION"/scripts/destroy-after-script.sh
fi
