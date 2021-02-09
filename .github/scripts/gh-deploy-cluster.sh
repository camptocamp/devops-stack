#!/bin/sh

# This hack is mendatory because we are using mount binds with absolute path in docker containers
mkdir -p "$RUNNER_WORKSPACE"
ln -s "$GITHUB_WORKSPACE" "$RUNNER_WORKSPACE/camptocamp-devops-stack"

export TF_ROOT="$RUNNER_WORKSPACE/camptocamp-devops-stack/$TF_ROOT" || exit

./scripts/provision.sh
