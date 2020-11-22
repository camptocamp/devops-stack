#!/bin/bash -e

ARGOCD_AUTH_TOKEN=$(jq -r '.ARGOCD_AUTH_TOKEN.value' terraform/outputs.json)
export ARGOCD_AUTH_TOKEN

ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"
export ARGOCD_OPTS

KUBECONFIG_CONTENT=$(jq -r '.KUBECONFIG_CONTENT.value' terraform/outputs.json)
export KUBECONFIG_CONTENT

while ! KUBECONFIG=<(echo "$KUBECONFIG_CONTENT") argocd app wait apps --health --timeout 30
do
	KUBECONFIG=<(echo "$KUBECONFIG_CONTENT") argocd app list -owide
done
