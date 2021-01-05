#!/bin/bash

[ $# -lt 1 ] && echo "Usage $0 <root app> [--only-application]" && exit 1
if [ "$2" = "--only-application" ]; then
  echo "Recursive Sync (only application)..."
  only_app=true
else
  echo "Recursive Sync..."
  only_app=false
fi

# Load some function to manage app status cache
source $(dirname $0)/argocd-app-status.sh

sync () {

  [ "$DEBUG" = 'true' ] && echo -n "Syncing $2$1..."
  sync_status=$(get_app_status $1)
  if [ "$sync_status" != "Synced" ]; then
    if [ "$only_app" = "true" ]; then
      # Search for resource of type 'argoproj.io/Application'
      resource_opts=""
      while IFS= read -r line; do
        group=$(echo $line | awk '{print $1}')
        kind=$(echo $line | awk '{print $2}')
        name=$(echo $line | awk '{print $4}')
        if [ "$group" = "argoproj.io" ] && [ "$kind" = "Application" ]; then
          resource_opts="$resource_opts --resource $group:$kind:$name"
        fi
      done < <(argocd app resources $1 2>/dev/null)
      if [ -n "$resource_opts" ]; then
        [ "$DEBUG" = 'true' ] && echo argocd app sync $1 $resource_opts
        argocd app sync $1 $resource_opts >/dev/null 2>&1
      fi
    else
      argocd app sync $1 >/dev/null 2>&1
    fi
    [ "$DEBUG" = 'true' ] && echo "OK"
    refresh_app_status
  else
    [ "$DEBUG" = 'true' ] && echo "Already Synced"
  fi
  # Sync child apps
  for app in $(kubectl get Application -l "app.kubernetes.io/instance=$1" --all-namespaces -o name | grep application.argoproj.io | cut -f 2 -d /); do
    if [ $app != $1 ]; then
      sync $app "${2}${1} -> "
    fi
  done
}
refresh_app_status
sync $1 ""
rm -fr $apps_status
if [ "$2" = "--only-application" ]; then
  echo "Recursive Sync (only application)...OK"
else
  echo "Recursive Sync...OK"
fi
