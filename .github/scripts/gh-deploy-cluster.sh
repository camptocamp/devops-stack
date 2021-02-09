#!/bin/sh

FLAVOR="$1"
REPO_URL="$GITHUB_SERVER_URL/$2/camptocamp-devops-stack.git"
TARGET_REVISION="$3"

mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$PATH"

wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O "$HOME/bin/jq"
chmod +x "$HOME/bin/jq"

wget https://get.helm.sh/helm-v3.4.0-linux-amd64.tar.gz -O - | tar xz linux-amd64/helm -O > "$HOME/bin/helm"
chmod +x "$HOME/bin/helm"

# This hack is mendatory because we are using mount binds with absolute path in docker containers
mkdir -p "$RUNNER_WORKSPACE"
ln -s "$GITHUB_WORKSPACE" "$RUNNER_WORKSPACE/camptocamp-devops-stack"
cd "$RUNNER_WORKSPACE/camptocamp-devops-stack/tests/$FLAVOR" || exit

export CLUSTER_NAME=default
export TF_VAR_repo_url="$REPO_URL"
export TF_VAR_target_revision="$TARGET_REVISION"

../../scripts/provision.sh
