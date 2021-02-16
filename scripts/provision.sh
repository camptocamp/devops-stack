#!/bin/sh

set -e

if ! command -v jq; then
	JQ_DIR=$(mktemp -d /tmp/jq.XXXXXX)
	export PATH="$JQ_DIR:$PATH"

	wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O "$JQ_DIR/jq"
	chmod +x "$JQ_DIR/jq"
fi

if ! command -v helm; then
	HELM_DIR=$(mktemp -d /tmp/helm.XXXXXX)
	export PATH="$HELM_DIR:$PATH"

	wget https://get.helm.sh/helm-v3.4.0-linux-amd64.tar.gz -O - | tar xz linux-amd64/helm -O > "$HELM_DIR/helm"
	chmod +x "$HELM_DIR/helm"
fi

export TF_WORKSPACE="$CLUSTER_NAME"

TF_ROOT="${TF_ROOT:-terraform}"

cd "$TF_ROOT" || exit
terraform init

# FIXME: Somehow Terraform's Helm provider does not do it even though
# I specified `dependency_update = true`
helm dependency update "$(jq -r '.Modules[]|select(.Key == "cluster").Dir + "/../../../argocd/argocd/"' .terraform/modules/modules.json)"

terraform apply --auto-approve
terraform plan --detailed-exitcode
terraform output -json > outputs.json
cd - || exit
