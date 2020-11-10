#!/bin/sh -e

account_pipeline_tokens=$(kubectl -n argocd get secrets argocd-secret -o=jsonpath="{.data['accounts\.pipeline\.tokens']}"|base64 -d)

# Create token for pipeline if not exists
if test -z "$account_pipeline_tokens"; then
	jti=$(cat /proc/sys/kernel/random/uuid)
	iat=$(date +%s)
	account_pipeline_tokens=$(printf "[{\"id\":\"%s\",\"iat\":%s}]" "$jti" "$iat"|base64 -w0)
	kubectl -n argocd patch secret argocd-secret -p "{\"data\": {\"accounts.pipeline.tokens\": \"$account_pipeline_tokens\"}}"
else
	jti=$(printf "%s" "$account_pipeline_tokens" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['id'])")
	iat=$(printf "%s" "$account_pipeline_tokens" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['iat'])")
fi

# Generate JWT token for "pipeline" user to connect to ArgoCD
iss="argocd"
nbf=$iat
sub="pipeline"
secret=$(kubectl -n argocd get secret argocd-secret -o=jsonpath="{.data['server\.secretkey']}" | base64 -d)

header=$(printf '{"alg":"HS256","typ":"JWT"}' | base64 -w0 | tr '/+' '_-' | tr -d '=')
payload=$(printf "{\"jti\":\"%s\",\"iat\":%s,\"iss\":\"%s\",\"nbf\":%s,\"sub\":\"%s\"}" "$jti" "$iat" "$iss" "$nbf" "$sub" | base64 -w0 | tr '/+' '_-' | tr -d '=')
signature=$(printf "%s.%s" "$header" "$payload" | openssl dgst -sha256 -hmac "$secret" -binary | base64 -w0 | tr '/+' '_-' | tr -d '=')

jq -n --arg token "$header.$payload.$signature" '{"token":$token}'
