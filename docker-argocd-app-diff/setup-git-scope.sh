if [ -z "$AAD_REPO_URL" ]; then
  if [ -n "$CI_REPOSITORY_URL" ]; then
    # Gitlab merge request env
    export AAD_REPO_URL=$CI_REPOSITORY_URL
  elif [ -n "$GITHUB_REPOSITORY" ]; then
    # Github pull requests env
    # FIXME add protocol in AAD_REPO_URL
    export AAD_REPO_URL=github.com/${GITHUB_REPOSITORY}.git
  else
    echo "Enable to auto detect git repo"
    echo "You can set manually: AAD_REPO_URL"
    exit 1
  fi
fi

if [ -z "$AAD_FEATURE_BRANCH" ]; then
  if [ -n "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME" ]; then
    export AAD_FEATURE_BRANCH=$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
  elif [ -n "$GITHUB_HEAD_REF" ]; then
    export AAD_FEATURE_BRANCH=$GITHUB_HEAD_REF
  else
    echo "Enable to auto detect feature branch."
    echo "You can set manually: AAD_FEATURE_BRANCH"
    exit 1
  fi
fi

if [ -z "$AAD_TARGET_BRANCH" ]; then
  if [ -n "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME" ]; then
    export AAD_TARGET_BRANCH=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
  elif [ -n "$GITHUB_BASE_REF" ]; then
    export AAD_TARGET_BRANCH=$GITHUB_BASE_REF
  else
    echo "Enable to auto detect target branch."
    echo "You can set manually: AAD_TARGET_BRANCH"
    exit 1
  fi
fi
