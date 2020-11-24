#!/bin/bash -e

ARGOCD_AUTH_TOKEN=$(python3 -c "import sys, json; print(json.load(sys.stdin)['argocd_auth_token']['value'])" < terraform/outputs.json)
export ARGOCD_AUTH_TOKEN

ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"
export ARGOCD_OPTS

KUBECONFIG_CONTENT=$(python3 -c "import sys, json; print(json.load(sys.stdin)['kubeconfig']['value'])" < terraform/outputs.json)
export KUBECONFIG_CONTENT

while ! KUBECONFIG=<(echo "$KUBECONFIG_CONTENT") argocd app wait apps --health --timeout 30
do
	KUBECONFIG=<(echo "$KUBECONFIG_CONTENT") argocd app list -owide
done
