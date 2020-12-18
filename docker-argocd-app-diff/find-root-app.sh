if [ -z "$AAD_ROOT_APP" ]; then
  for app in $(argocd app list -o name); do
    [ "$DEBUG" = 'true' ] && echo "App: $app"
    manifest=$(mktemp)
    argocd app get $app -o yaml > $manifest
    parent_app=$(yq r $manifest 'metadata.labels."app.kubernetes.io/instance"')
    git_repo=$(yq r $manifest 'spec.source.repoURL')
    git_branch=$(yq r $manifest 'spec.source.targetRevision')
    rm $manifest

    # check repo
    if [ $AAD_REPO_URL != $git_repo ]; then
      [ "$DEBUG" = 'true' ] && echo "Skipping app $app: defined in another repo ($AAD_REPO_URL != $git_repo)"
      continue
    fi

    # check branch
    if [ $AAD_TARGET_BRANCH != $git_branch ]; then
      [ "$DEBUG" = 'true' ] && echo "Skipping app $app: use anothe branch ($AAD_TARGET_BRANCH != $git_branch)"
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
  done
  [ -z "$AAD_ROOT_APP" ] && echo "Cannot find root app" && echo exit 1
else
  echo "Root app already set: $AAD_ROOT_APP"
fi
