#!/bin/sh -xe

API_IP_ADDRESS=$(jq -r '.values.root_module.resources[]|select(.type=="docker_container" and .name=="k3s_server").values.ip_address' "$ARTIFACTS_DIR/terraform.tfstate.json")
echo "$(echo "$API_IP_ADDRESS"|tr '.' '-').nip.io"
