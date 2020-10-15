#!/bin/sh -xe

API_IP_ADDRESS=$(jq -r '.resources[]|select(.type=="docker_container" and .name=="k3s_server").instances[0].attributes.ip_address' "$ARTIFACTS_DIR/terraform.tfstate")
echo "$(echo "$API_IP_ADDRESS"|tr '.' '-').nip.io"
