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
  apps_manifests=$(mktemp -d)
  kubectl get Application --all-namespaces -o yaml > $apps_manifests/apps.yaml

  yq r $apps_manifests/apps.yaml 'items[*].metadata.name' > $apps_manifests/names.yaml
  yq r $apps_manifests/apps.yaml 'items[*].status.sync.status' > $apps_manifests/status.yaml

  rm -fr $apps_status/*
  while IFS= read -r line
  do
    name=$(echo $line | cut -f 1 -d ' ')
    sync_status=$(echo $line | cut -f 2 -d ' ')
    echo $sync_status > $apps_status/$name
  done < <(paste -d ' ' $apps_manifests/names.yaml $apps_manifests/status.yaml)
  rm -fr $apps_manifests
  [ "$DEBUG" = 'true' ] && echo "OK"
}

sync () {

  [ "$DEBUG" = 'true' ] && echo -n "Syncing $2$1..."
  sync_status=$(cat $apps_status/$1)
  if [ "$sync_status" != "Synced" ]; then
    if [ "$only_app" = "true" ]; then
      argocd app sync $1 $(argocd app manifests $1 | yq r -c -d '*' - | yq p - a | yq r - 'a.(kind==Application).metadata.name' | sed -e 's/^/--resource argoproj.io:Application:/' | xargs) >/dev/null 2>&1
    else
      argocd app sync $1 >/dev/null 2>&1
    fi
    [ "$DEBUG" = 'true' ] && echo "OK"
    update_sync_status
  else
    [ "$DEBUG" = 'true' ] && echo "Already Synced"
  fi
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
