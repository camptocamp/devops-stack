#!/bin/bash

[ $# -lt 1 ] && echo "Usage $0 <root app> [<app path>]" && exit 1
[ -n "$DEBUG" ] && set -xe

echo "Disabling Auto Sync..."
argocd app set $1 --helm-set spec.syncPolicy= --sync-policy none >/dev/null 2>&1
argocd app wait $1 --operation >/dev/null 2>&1
sleep 1
$(dirname $0)/argocd-recursive-sync.sh $1
echo "Disabling Auto Sync...OK"
