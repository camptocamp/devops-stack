#!/bin/sh -xe

. get-argocd-auth-token.sh

export ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"

echo ARGOCD_AUTH_TOKEN="$ARGOCD_AUTH_TOKEN"

argocd app list -owide

for app_dir in ../../argocd/*;
do
	app=${app_dir#../../argocd/}
	app=${app%*/}
	test -f "$app_dir/Chart.yaml" && helm dependency update "$app_dir"
	argocd app diff "$app" --local "$app_dir" || true
done
