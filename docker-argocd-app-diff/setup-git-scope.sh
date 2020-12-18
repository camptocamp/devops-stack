if [ -z "$AAD_REPO_URL" ]; then
  if [ -n "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME" ]; then
    # Gitlab merge request env
    export AAD_REPO_URL=$CI_REPOSITORY_URL
    export AAD_FEATURE_BRANCH=$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
    export AAD_TARGET_BRANCH=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
  elif [ -n "$GITHUB_HEAD_REF" ]; then
    # Github pull requests env
    # FIXME add protocol in AAD_REPO_URL
    # FIXME not tested
    export AAD_REPO_URL=github.com/${GITHUB_REPOSITORY}.git
    export AAD_FEATURE_BRANCH=$GITHUB_HEAD_REF
    export AAD_TARGET_BRANCH=$GITHUB_BASE_REF
  else
    echo "Enable to auto detect git repo, source and target branch."
    echo "You can set manually: AAD_REPO_URL, AAD_FEATURE_BRANCH, AAD_TARGET_BRANCH"
    exit 1
  fi
fi

for var in AAD_REPO_URL AAD_FEATURE_BRANCH AAD_TARGET_BRANCH; do
  [ -z "${!var}" ] && echo "Enable to compute $var" && exit 1
done
