#!/bin/bash

if [ -z "$AAD_ROOT_APP" ]; then

  while IFS= read -r line; do
    app=$(echo $line | cut -f 1 -d ' ')
    parent_app=$(echo $line | cut -f 2 -d ' ')
    git_repo=$(echo $line | cut -f 3 -d ' ')
    git_branch=$(echo $line | cut -f 4 -d ' ')
    [ "$DEBUG" = 'true' ] && echo "App: $parent_app -> $app ($git_branch@$git_repo)"

    # check repo
    # TODO try to match with different protocol : http/ssh/git
    if [ $AAD_REPO_URL != $git_repo ]; then
      [ "$DEBUG" = 'true' ] && echo "Skipping app $app: defined in another repo ($AAD_REPO_URL != $git_repo)"
      continue
    fi

    # check branch
    if [ $AAD_TARGET_BRANCH != $git_branch ]; then
      [ "$DEBUG" = 'true' ] && echo "Skipping app $app: use another branch ($AAD_TARGET_BRANCH != $git_branch)"
      continue
    fi

    # Root app have no parent or self parent
    if [ -z "$parent_app" ] || [ "$parent_app" = "$app" ]; then
      echo "Found root app: $app"
      if [ -z "$AAD_ROOT_APP" ]; then
        export AAD_ROOT_APP=$app
      else
        echo "Root app already found : $AAD_ROOT_APP, other root app : $app"
        exit 1
      fi
    fi
  done < <(kubectl get Application --all-namespaces -o json | jq -r '.items[] | "\(.metadata.name) \(.metadata.labels["app.kubernetes.io/instance"]) \(.spec.source.repoURL) \(.spec.source.targetRevision)"')
  [ -z "$AAD_ROOT_APP" ] && echo "Cannot find root app" && exit 1
else
  echo "Root app already set: $AAD_ROOT_APP"
fi
