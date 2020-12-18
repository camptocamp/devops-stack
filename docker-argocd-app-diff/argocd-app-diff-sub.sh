#!/bin/bash

[ -z "$1" ] && echo "Usage $0 <argocd app> [<logical app path>]" && exit 1
[ -z "$APPS_DEPLOYED_DIR" ] && echo "APPS_DEPLOYED_DIR must be set" && exit 1

mkdir -p $APPS_DEPLOYED_DIR/$1
export CURRENT_ARGOCD_APP=$1

# Compute diff
diff=$(mktemp)
argocd app diff $1 | sed 's/===== \(.*\)\/\(.*\) \(.*\)\/\(.*\) ======/* ApiGroup: \1\n* Kind: \2\n* Namespace: \3\n* Name: \4/g' > $diff

# Don't display title id there is no diff
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "## ${2}${1}"
  cat $diff
else
  echo "*No modifications for ${2}${1}*"
fi

# Run diff on child apps
apps_in_app=$(argocd app manifests $1 | yq r -c -d '*' - | yq p - a | yq r - 'a.(kind==Application).metadata.name')
for app in $(echo $apps_in_app); do
  if [ $app != $1 ]; then # Don't recurse of current app

    # Synchronise app to load app or update sync policy and target revision
    echo "Syncing $app in $1"
    argocd app sync $1 --resource argoproj.io:Application:${app} > /dev/null 2>&1
    argocd app wait ${app} --operation > /dev/null 2>&1
    # Recursion
    $0 $app "${2}${1} -> "
  fi
done
