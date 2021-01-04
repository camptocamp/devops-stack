# Generate/Fetch ArgoCD Auth token
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
[ "$DEBUG" = "true" ] && echo "Successfull fetch of ArgoCD token"
