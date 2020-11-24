#!/bin/bash -e

ARGOCD_AUTH_TOKEN=$(python3 -c "import sys, json; print(json.load(sys.stdin)['argocd_auth_token']['value'])" < terraform/outputs.json)
export ARGOCD_AUTH_TOKEN

ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"
export ARGOCD_OPTS

KUBECONFIG_CONTENT=$(python3 -c "import sys, json; print(json.load(sys.stdin)['kubeconfig']['value'])" < terraform/outputs.json)
export KUBECONFIG_CONTENT

export KUBECTL_EXTERNAL_DIFF="diff -u"

for app_dir in ../../argocd/*;
do
	app=${app_dir#../../argocd/}
	test -f "$app_dir/Chart.yaml" && helm dependency update "$app_dir"
	KUBECONFIG=<(echo "$KUBECONFIG_CONTENT") argocd app diff "$app" --local "$app_dir" || true
done
