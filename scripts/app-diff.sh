#!/bin/sh -xe

argocd app list -owide

for app_dir in ../../argocd/*;
do
	app=${app_dir#../../argocd/}
	app=${app%*/}
	test -f "$app_dir/Chart.yaml" && helm dependency update "$app_dir"
	argocd app diff "$app" --local "$app_dir" || true
done
