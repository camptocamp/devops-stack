#!/bin/bash

[ $# -ne 2 ] && echo "Usage $0 <root app> <feature branch>" && exit 1
[ -n "$DEBUG" ] && set -xe

$(dirname $0)/argocd-disable-auto-sync.sh $1
echo "Switch to $2..."
argocd app set $1 --helm-set spec.source.targetRevision=$2 # --revision $2
argocd app wait $1 --operation > /dev/null 2>&1
sleep 1
$(dirname $0)/argocd-recursive-sync.sh $1 --only-application
echo "Switch to $2...OK"

echo "Ready For diff"
