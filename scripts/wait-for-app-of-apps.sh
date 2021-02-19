#!/bin/bash

set -e

pwd
echo HOME="$HOME"

echo "$ARGOCD_AUTH_TOKEN"

cat ~/.kube/config

ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"
export ARGOCD_OPTS

while ! argocd app wait apps --sync --health --timeout 30
do
	argocd app list -owide || true
done
