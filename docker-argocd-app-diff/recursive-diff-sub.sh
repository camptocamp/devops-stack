#!/bin/bash

[ -z "$1" ] && echo "Usage $0 <argocd app> [<logical app path>]" && echo "No app specified" && exit 1

# Load some function to manage app status cache
source $(dirname $0)/argocd-app-status.sh
app_status=$(get_app_status $1)

if [ "$app_status" != "Synced" ]; then

  # Compute diff
  diff=$(mktemp)
  argocd app diff $1 2>/dev/null | sed 's/===== \(.*\)\/\(.*\) \(.*\)\/\(.*\) ======/* ApiGroup: \1\n* Kind: \2\n* Namespace: \3\n* Name: \4/g' > $diff

  # Don't display title id there is no diff
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "## ${2}${1}"
    cat $diff
  else
  [ "$DEBUG" = "true" ] && echo "${1} not Synced, empty diff computed"
    echo "*No modifications for ${2}${1}*"
  fi
else
  [ "$DEBUG" = "true" ] && echo "${1} Synced, no diff computed"
  echo "*No modifications for ${2}${1}*"
fi

# Run diff on child apps
while IFS= read -r line; do
  group=$(echo $line | awk '{print $1}')
  kind=$(echo $line | awk '{print $2}')
  name=$(echo $line | awk '{print $4}')
  if [ "$group" = "argoproj.io" ] && [ "$kind" = "Application" ] && [ $name != $1 ]; then
    if [ "$(get_app_status $name)" != "Synced" ]; then
      # Synchronise app to load app or update sync policy and target revision
      [ "$DEBUG" = 'true' ] && echo "Syncing $name in $1"
      argocd app sync $1 --resource argoproj.io:Application:${name} > /dev/null 2>&1
      argocd app wait ${name} --operation > /dev/null 2>&1
      update_app_status ${name}
    else
      [ "$DEBUG" = "true" ] && echo "No need to sync $name"
    fi
    # Recursion
    $0 $name "${2}${1} -> "
  fi
done < <(argocd app resources $1 2>/dev/null)
