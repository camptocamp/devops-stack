#!/bin/sh

REPO_URL="$GITHUB_SERVER_URL/$1/camptocamp-devops-stack.git"
TARGET_REVISION="$2"

# This hack is mendatory because we are using mount binds with absolute path in docker containers
mkdir -p "$RUNNER_WORKSPACE"
ln -s "$GITHUB_WORKSPACE" "$RUNNER_WORKSPACE/camptocamp-devops-stack"

export TF_ROOT="$RUNNER_WORKSPACE/camptocamp-devops-stack/$TF_ROOT" || exit
export CLUSTER_NAME=default
export TF_VAR_repo_url="$REPO_URL"
export TF_VAR_target_revision="$TARGET_REVISION"

./scripts/provision.sh
