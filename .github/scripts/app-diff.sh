#!/bin/bash

# This script requires this environment variables to be set:
#
# - KUBECONFIG: pointing to a file containing the Kubernetes context to use as we use port-forwarding
# - ARGOCD_SERVER: The URL of the ArgoCD server
# - ARGOCD_AUTH_TOKEN: a read-only token that is allowed to perform argocd app list and argocd app diff
# - REPO_URL: the repoUrl of the destination DevOps stack
# - TARGET_REVISION: the targetRevision of the destination DevOps Stack
#
# It also requires 2 files ro be present (TODO: find a better approach for this):
# - values0.yaml
# - values1.yaml
# - values2.yaml

set -e

export KUBECTL_EXTERNAL_DIFF="diff -u"
# TODO: find a way to disable this flags
export ARGOCD_OPTS="--insecure --grpc-web"

cd /tmp || exit

git clone "$REPO_URL"
cd devops-stack || exit
git checkout "$TARGET_REVISION"
cd - || exit

echo Update app of apps without syncPolicy
helm -n argocd upgrade app-of-apps devops-stack/argocd/app-of-apps \
	-f "$APP_OF_APPS_VALUES_0" \
	-f "$APP_OF_APPS_VALUES_1" \
	-f "$APP_OF_APPS_VALUES_2" \
	--set spec.syncPolicy= --wait

echo Waiting for app of apps to sync
echo Sleep 3 seconds
sleep 3
argocd app wait apps --sync
echo Sleep 3 seconds
sleep 3

for app in $(argocd app list -oname)
do
	echo "Diffing $app..."
	argocd app diff "$app" --refresh || true
done

helm -n argocd rollback app-of-apps
