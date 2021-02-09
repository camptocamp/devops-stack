#!/bin/sh

set -e

export PATH="$HOME/bin:$PATH"
export TF_WORKSPACE="$CLUSTER_NAME"

mkdir -p "$HOME/bin"
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O "$HOME/bin/jq"
chmod +x "$HOME/bin/jq"

TF_ROOT="${TF_ROOT:-terraform}"

cd "$TF_ROOT" || exit
terraform init
terraform plan -out plan
terraform show -json plan | jq -r '.planned_values.outputs' > outputs.json
cd - || exit
