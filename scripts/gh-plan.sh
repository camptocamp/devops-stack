#!/bin/sh

FLAVOR="$1"

mkdir -p "$RUNNER_WORKSPACE"
ln -s "$GITHUB_WORKSPACE" "$RUNNER_WORKSPACE/camptocamp-devops-stack"
cd "$RUNNER_WORKSPACE/camptocamp-devops-stack/tests/$FLAVOR" || exit

export CLUSTER_NAME=default
export TF_VAR_repo_url="$2"
export TF_VAR_target_revision="$3"

../../scripts/plan.sh
