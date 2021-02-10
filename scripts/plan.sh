#!/bin/sh

set -e

if ! command -v jq; then
	JQ_DIR=$(mktemp -d /tmp/jq.XXXXXX)
	export PATH="$JQ_DIR:$PATH"

	wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O "$JQ_DIR/jq"
	chmod +x "$JQ_DIR/jq"
fi

export TF_WORKSPACE="$CLUSTER_NAME"

TF_ROOT="${TF_ROOT:-terraform}"

cd "$TF_ROOT" || exit
terraform init
terraform plan -out plan
terraform show -json plan | jq -r '.planned_values.outputs' > outputs.json
cd - || exit
