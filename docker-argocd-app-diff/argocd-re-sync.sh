#!/bin/bash

[ $# -ne 2 ] && echo "Usage $0 <root app> <default branch>" && exit 1
[ -n "$DEBUG" ] && set -xe

# Sync target revision first
argocd app set $1 --helm-set spec.syncPolicy= --helm-set spec.source.targetRevision=$2 --revision $2
argocd app sync $1 --prune
argocd app wait $1 --operation > /dev/null 2>&1

# Sync syncPolicy
argocd app unset $1 -p spec.syncPolicy -p spec.source.targetRevision
argocd app sync $1 --prune
argocd app wait $1 --sync
