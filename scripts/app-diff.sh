#!/bin/bash

set -e

python3 -c "import sys, json; print(json.load(sys.stdin)['kubeconfig']['value'])" < terraform/outputs.json > kubeconfig.yaml
chmod 0600 kubeconfig.yaml
export KUBECONFIG=kubeconfig.yaml

ARGOCD_AUTH_TOKEN=$(python3 -c "import sys, json; print(json.load(sys.stdin)['argocd_auth_token']['value'])" < terraform/outputs.json)
export ARGOCD_AUTH_TOKEN

REPO_URL=$(python3 -c "import sys, json; print(json.load(sys.stdin)['repo_url']['value'])" < terraform/outputs.json)
TARGET_REVISION=$(python3 -c "import sys, json; print(json.load(sys.stdin)['target_revision']['value'])" < terraform/outputs.json)

# FIXME: find a more robust way to do this
APP_OF_APPS_VALUES_0=$(python3 -c "import sys, json; print(json.load(sys.stdin)['app_of_apps_values']['value'][0])" < terraform/outputs.json)
APP_OF_APPS_VALUES_1=$(python3 -c "import sys, json; print(json.load(sys.stdin)['app_of_apps_values']['value'][1])" < terraform/outputs.json)
APP_OF_APPS_VALUES_2=$(python3 -c "import sys, json; print(json.load(sys.stdin)['app_of_apps_values']['value'][2])" < terraform/outputs.json)

export KUBECTL_EXTERNAL_DIFF="diff -u"
export ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"

git clone "$REPO_URL"
cd camptocamp-devops-stack || exit
git checkout "$TARGET_REVISION"
cd - || exit

helm version

echo Update app of apps without syncPolicy
date
helm -n argocd upgrade app-of-apps camptocamp-devops-stack/argocd/app-of-apps \
	-f <(echo "$APP_OF_APPS_VALUES_0") \
	-f <(echo "$APP_OF_APPS_VALUES_1") \
	-f <(echo "$APP_OF_APPS_VALUES_2") \
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
date
