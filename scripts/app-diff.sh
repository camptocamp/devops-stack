#!/bin/bash

# This script requires this environment variables to be set:
#
# - KUBECONFIG: pointing to a file containing the Kubernetes context to use as we use port-forwarding
# - ARGOCD_AUTH_TOKEN: a read-only token that is allowed to perform argocd app list and argocd app diff
#
# It also requires 2 files ro be present (TODO: find a better approach for this):
# - values0.yaml
# - values1.yaml
# - values2.yaml

set -e

export KUBECTL_EXTERNAL_DIFF="diff -u"
export ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"

cd /tmp || exit

git clone "$REPO_URL"
cd camptocamp-devops-stack || exit
git checkout "$TARGET_REVISION"
cd - || exit

echo Update app of apps without syncPolicy
helm -n argocd upgrade app-of-apps camptocamp-devops-stack/argocd/app-of-apps \
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
