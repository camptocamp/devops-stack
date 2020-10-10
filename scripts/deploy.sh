#!/bin/sh -xe

# Install ArgoCD if not present
if test "$(kubectl -n argocd get pods --selector 'app.kubernetes.io/name=argocd-server' --output=name|wc -l)" -eq 0; then
	helm dependency update argocd/argocd
	kubectl create namespace argocd || true
	helm template --include-crds argocd argocd/argocd --values "$ARTIFACTS_DIR/values.yaml" --set bootstrap=true --namespace argocd | kubectl "$KUBECTL_COMMAND" -n argocd -f -
	while test "$(kubectl -n argocd get pods --selector 'app.kubernetes.io/name=argocd-server' --output=name | wc -l)" -eq 0; do
		echo Waiting for pods in argocd namespace
		sleep 3
	done
	kubectl -n argocd wait "$(kubectl -n argocd get pods --selector 'app.kubernetes.io/name=argocd-server' --output=name)" --for=condition=Ready --timeout=-1s
	kubectl -n argocd wait "$(kubectl -n argocd get pods --selector 'app.kubernetes.io/name=argocd-repo-server' --output=name)" --for=condition=Ready --timeout=-1s
fi

account_pipeline_tokens=$(kubectl -n argocd get secrets argocd-secret -o=jsonpath="{.data['accounts\.pipeline\.tokens']}"|base64 -d)
# Create token for pipeline if not exists
if test -z "$account_pipeline_tokens"; then
	jti=$(cat /proc/sys/kernel/random/uuid)
	iat=$(date +%s)
	account_pipeline_tokens=$(echo -n "[{\"id\":\"$jti\",\"iat\":$iat}]"|base64 -w0)
	# FIXME: KUBECTL_OPTIONS is intentionally not quoted in the following command, because kubectl would take en empty string as resource type
	kubectl -n argocd patch $KUBECTL_OPTIONS secret argocd-secret -p "{\"data\": {\"accounts.pipeline.tokens\": \"$account_pipeline_tokens\"}}"
else
	jti=$(echo -n "$account_pipeline_tokens" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['id'])")
	iat=$(echo -n "$account_pipeline_tokens" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['iat'])")
fi

# Generate JWT token for "pipeline" user to connect to ArgoCD
iss="argocd"
nbf=$iat
sub="pipeline"
secret=$(kubectl -n argocd get secret argocd-secret -o=jsonpath="{.data['server\.secretkey']}" | base64 -d)

header=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64 -w0 | tr '/+' '_-' | tr -d '=')
payload=$(echo -n "{\"jti\":\"$jti\",\"iat\":$iat,\"iss\":\"$iss\",\"nbf\":$nbf,\"sub\":\"$sub\"}" | base64 -w0 | tr '/+' '_-' | tr -d '=')
signature=$(echo -n "$header.$payload" | openssl dgst -sha256 -hmac "$secret" -binary | base64 -w0 | tr '/+' '_-' | tr -d '=')

export ARGOCD_AUTH_TOKEN=$header.$payload.$signature

argocd app list

# Deploy or update app of apps
helm template apps argocd/apps \
	--values "$ARTIFACTS_DIR/values.yaml" \
	-s templates/apps.yaml | kubectl "$KUBECTL_COMMAND" -n argocd -f - || true

# TODO: Don't use Gitlab CI specific variable in scripts
if test -n "$CI_MERGE_REQUEST_ID"; then
	# TODO: use argocd cli to loop over applications
	cd argocd || return
	for app in */;
	do
		app=${app%*/}
		(
		cd "$app" || return
		test -f Chart.yaml && helm dependency update
		argocd app diff "$app" --local . || true
	)
  done
else
	argocd app list
	echo "Waiting for app of apps to be in sync"
	# FIXME: Because we are using port-forward to communicate with ArgoCD, we
	# have to log in again when ArgoCD is redeployed (which is the case during
	# bootstrap). This has to be improved eventually.
	while ! argocd app wait apps --health --timeout 30; do
		kubectl get pods --all-namespaces
	done
fi
