#!/bin/bash

[ -z "$1" ] && echo "Usage $0 <argocd app> [<logical app path>]" && echo "No app specified" && exit 1

export KUBECTL_EXTERNAL_DIFF=$(dirname $(realpath $0))/custom-diff-tool.sh

# Load some function to manage app status cache
source $(dirname $0)/argocd-app-status.sh
refresh_app_status
$(dirname $0)/recursive-diff-sub.sh $*
