#!/bin/sh

FLAVOR="$1"

mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$PATH"

wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O "$HOME/bin/jq"
chmod +x "$HOME/bin/jq"

wget https://get.helm.sh/helm-v3.4.0-linux-amd64.tar.gz -O - | tar xz linux-amd64/helm -O > "$HOME/bin/helm"
chmod +x "$HOME/bin/helm"

env|grep GITHUB_
env|grep ACTIONS_
env|grep RUNNER_
env|grep INPUT_

# This hack is mendatory because we are using mount binds with absolute path in docker containers
mkdir -p "$RUNNER_WORKSPACE"
ln -s "$GITHUB_WORKSPACE" "$RUNNER_WORKSPACE/camptocamp-devops-stack"
cd "$RUNNER_WORKSPACE/camptocamp-devops-stack/tests/$FLAVOR" || exit

export CLUSTER_NAME=default
export TF_VAR_repo_url="$2"
export TF_VAR_target_revision="$3"

../../scripts/provision.sh
