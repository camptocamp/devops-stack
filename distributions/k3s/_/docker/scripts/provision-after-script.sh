#!/bin/sh -xe

wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ~/jq
chmod +x ~/jq

# Create values.yaml for ArgoCD app of apps
cat << EOF > "$ARTIFACTS_DIR/values.yaml"
---
spec:
  source:
    repoURL: $REPO_URL
    targetRevision: $CLUSTER_NAME

baseDomain: $(~/jq -r '.resources[]|select(.type=="docker_container" and .name=="k3s_server").instances[0].attributes.ip_address|gsub("\\.";"-") + ".nip.io"' "$ARTIFACTS_DIR/terraform.tfstate")
EOF
