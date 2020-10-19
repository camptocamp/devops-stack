#!/bin/sh -xe

echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' > "$HOME/.terraformrc"

if test -x distributions/"$DISTRIBUTION"/scripts/provision-before-script.sh; then
	distributions/"$DISTRIBUTION"/scripts/provision-before-script.sh
fi

cd distributions/"$DISTRIBUTION"/terraform || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform apply --auto-approve
terraform plan --detailed-exitcode
cd -

if test -x distributions/"$DISTRIBUTION"/scripts/provision-after-script.sh; then
	distributions/"$DISTRIBUTION"/scripts/provision-after-script.sh
fi
