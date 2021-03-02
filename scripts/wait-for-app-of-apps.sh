#!/bin/bash

# This script requires this environment variables to be set:
#
# - KUBECONFIG: pointing to a file containing the Kubernetes context to use as we use port-forwarding
# - ARGOCD_AUTH_TOKEN: a read-only token that is allowed to perform argocd app list and argocd app diff

set -e

export ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"

while ! argocd app wait apps --sync --health --timeout 30
do
	argocd app list -owide || true
done
