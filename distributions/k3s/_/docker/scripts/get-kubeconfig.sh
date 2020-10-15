#!/bin/sh -xe

docker cp "k3s-server-$CLUSTER_NAME:/etc/rancher/k3s/k3s.yaml" "$ARTIFACTS_DIR/kubeconfig.yaml"
sed -i -e "s/127.0.0.1/$API_IP_ADDRESS/" "$ARTIFACTS_DIR/kubeconfig.yaml"
