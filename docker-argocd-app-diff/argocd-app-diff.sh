#!/bin/bash

[ -z "$1" ] && echo "Usage $0 <argocd app> [<path to save manifests]" && echo "No app specified" && exit 1
[ $# -gt 2 ] && echo "Usage $0 <argocd app> [<path to save manifests]" && echo "Extra parameters" && exit 1
[ -n "$2" ] && [ ! -d "$2" ] && echo "'$2' is not a directory" && exit 1


if [ -n "$2" ]; then
  export APPS_DEPLOYED_DIR=$2
else
  export APPS_DEPLOYED_DIR=$(mktemp -d)
fi

export KUBECTL_EXTERNAL_DIFF=$(dirname $(realpath $0))/custom-diff-tool.sh
$(dirname $(realpath $0))/argocd-app-diff-sub.sh $1

[ -z "$2" ] && rm -fr $APPS_DEPLOYED_DIR
