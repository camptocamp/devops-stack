#!/bin/bash

refresh_app_status () {
  [ "$DEBUG" = 'true' ] && echo -n "Refresh app status..."
  rm -fr /tmp/app_status
  mkdir /tmp/app_status

  while IFS= read -r line; do
    name=$(echo $line | cut -f 1 -d ' ')
    sync_status=$(echo $line | cut -f 2 -d ' ')
    echo $sync_status > /tmp/app_status/$name
  done < <(argocd app list -o json 2> /dev/null | jq -r '.[] | "\(.metadata.name) \(.status.sync.status)"')
  [ "$DEBUG" = 'true' ] && echo "OK"

}

get_app_status () {
    cat /tmp/app_status/$1
}

update_app_status () {
  argocd app get $1 -o json 2> /dev/null | jq -r '.status.sync.status' > /tmp/app_status/$1
}
