#!/bin/bash

# Configure access to cluster
# Set KUBECONFIG
source $(dirname $0)/configure-cluster-access.sh
echo ""
echo "Kubernetes Configuration"
echo "------------------------"
kubectl cluster-info

# Select scope based on current git repo
# Set AAD_REPO_URL, AAD_FEATURE_BRANCH, AAD_TARGET_BRANCH
# AAD_REPO_URL: URL of git repo used to filter apps
# AAD_FEATURE_BRANCH: Feature branch that contains new version of manifests
# AAD_TARGET_BRANCH: Target branch for merge
source $(dirname $0)/setup-git-scope.sh
echo ""
echo "Merge Request"
echo "-------------"
echo "For merge requet on $AAD_REPO_URL"
echo "$AAD_FEATURE_BRANCH --> $AAD_TARGET_BRANCH"

# Login to ArgoCD
# Set ARGOCD_SERVER, ARGOCD_AUTH_TOKEN and ARGOCD_OPTS
source $(dirname $0)/argocd-fetch-token.sh
source $(dirname $0)/argocd-fetch-server.sh
echo ""
echo "ArgoCD Configuration"
echo "--------------------"
echo "ArgoCD URL: $ARGOCD_SERVER"
argocd version

# Try to find the top level app of apps
# Diff should start on root app defined by this repo
# Set AAD_ROOT_APP
source $(dirname $0)/find-root-app.sh
echo ""
echo "ArgoCD Root App"
echo "---------------"
echo "Root App: $AAD_ROOT_APP"

exec $@
