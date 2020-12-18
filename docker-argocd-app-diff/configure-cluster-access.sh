if [ -z "$KUBECONFIG" ]; then
  echo "Missing configuration to access cluster. KUBECONFIG mlust be set."
  exit 1
fi

kubectl cluster-info > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Cannot connect k8s cluster with KUBECONFIG=$KUBECONFIG"
  exit 2
fi
