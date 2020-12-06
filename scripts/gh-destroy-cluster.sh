#!/bin/sh

FLAVOR="$1"
REPO_URL="$GITHUB_SERVER_URL/$2/camptocamp-devops-stack.git"
TARGET_REVISION="$3"

mkdir -p "$RUNNER_WORKSPACE"
ln -s "$GITHUB_WORKSPACE" "$RUNNER_WORKSPACE/camptocamp-devops-stack"
cd "$RUNNER_WORKSPACE/camptocamp-devops-stack/tests/$FLAVOR" || exit

export CLUSTER_NAME=default
export TF_VAR_repo_url="$REPO_URL"
export TF_VAR_target_revision="$TARGET_REVISION"

../../scripts/destroy.sh
