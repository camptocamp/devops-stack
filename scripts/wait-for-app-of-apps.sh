#!/bin/bash

set -e

TF_ROOT="${TF_ROOT:-terraform}"

KUBECONFIG=$(mktemp /tmp/kubeconfig.XXXXXX)
export KUBECONFIG

python3 -c "import sys, json; print(json.load(sys.stdin)['kubeconfig']['value'])" < "$TF_ROOT/outputs.json" > "$KUBECONFIG"
chmod 0600 "$KUBECONFIG"

ARGOCD_AUTH_TOKEN=$(python3 -c "import sys, json; print(json.load(sys.stdin)['argocd_auth_token']['value'])" < "$TF_ROOT/outputs.json")
export ARGOCD_AUTH_TOKEN

ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"
export ARGOCD_OPTS

while ! argocd app wait apps --sync --health --timeout 30
do
	argocd app list -owide || true
done

rm "$KUBECONFIG"
