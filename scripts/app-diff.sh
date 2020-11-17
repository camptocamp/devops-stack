#!/bin/sh -e

export KUBECTL_EXTERNAL_DIFF="diff -u"

for app_dir in ../../argocd/*;
do
	app=${app_dir#../../argocd/}
	test -f "$app_dir/Chart.yaml" && helm dependency update "$app_dir"
	argocd app diff "$app" --local "$app_dir" || true
done
