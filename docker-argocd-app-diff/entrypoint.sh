#!/bin/bash

# Configure access to cluster
# Set KUBECONFIG
source /usr/local/bin/configure-cluster-access.sh

# Select scope based on current git repo
# Set AAD_REPO_URL, AAD_FEATURE_BRANCH, AAD_TARGET_BRANCH
# AAD_REPO_URL: URL of git repo used to filter apps
# AAD_FEATURE_BRANCH: Feature branch that contains new version of manifests
# AAD_TARGET_BRANCH: Target branch for merge
source /usr/local/bin/setup-git-scope.sh

# Login to ArgoCD
# Set ARGOCD_SERVER, ARGOCD_AUTH_TOKEN and ARGOCD_OPTS
source /usr/local/bin/argocd-fetch-token.sh
source /usr/local/bin/argocd-fetch-server.sh

# Try to find the top level app of apps
# Diff should start on root app defined by this repo
# Set AAD_ROOT_APP
source /usr/local/bin/find-root-app.sh

# Compute Diff
mkdir -p app_diff_manifests
export DEBUG=TRUE
set -x

# 1. Disable auto sync and use feature branch for argocd
argocd-switch-to-feature-branch.sh ${AAD_ROOT_APP} ${AAD_FEATURE_BRANCH}

# 2. Run app diff on top level app of apps
# * Display diff
# * Deploy any Application
# * Run App Diff in all Application (new, modified, ...)
scripts/argocd-app-diff.sh ${ARGOCD_ROOT_APP} app_diff_manifests || true

# 3. Revert modification
scripts/argocd-re-sync.sh ${ARGOCD_ROOT_APP} ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME} > /dev/null
