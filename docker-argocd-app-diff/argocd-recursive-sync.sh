#!/bin/bash

[ $# -lt 1 ] && echo "Usage $0 <root app> [--only-application]" && exit 1
if [ "$2" = "--only-application" ]; then
  echo "Recursive Sync (only application)..."
  only_app=true
else
  echo "Recursive Sync..."
  only_app=false
fi

apps_status=$(mktemp -d)

update_sync_status () {
  [ "$DEBUG" = 'true' ] && echo -n "Refresh app status..."

  rm -fr $apps_status/*
  while IFS= read -r line; do
    name=$(echo $line | cut -f 1 -d ' ')
    sync_status=$(echo $line | cut -f 2 -d ' ')
    echo $sync_status > $apps_status/$name
  done < <(kubectl get Application --all-namespaces -o json | jq -r '.items[] | "\(.metadata.name) \(.status.sync.status)"')
  [ "$DEBUG" = 'true' ] && echo "OK"
}

sync () {

  [ "$DEBUG" = 'true' ] && echo -n "Syncing $2$1..."
  sync_status=$(cat $apps_status/$1)
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
      done < <(argocd app resources apps)
      if [ -n "$resource_opts" ]; then
        [ "$DEBUG" = 'true' ] && echo argocd app sync $1 $resource_opts
        argocd app sync $1 $resource_opts >/dev/null 2>&1
      fi
    else
      argocd app sync $1 >/dev/null 2>&1
    fi
    [ "$DEBUG" = 'true' ] && echo "OK"
    update_sync_status
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
update_sync_status
sync $1 ""
rm -fr $apps_status
if [ "$2" = "--only-application" ]; then
  echo "Recursive Sync (only application)...OK"
else
  echo "Recursive Sync...OK"
fi
