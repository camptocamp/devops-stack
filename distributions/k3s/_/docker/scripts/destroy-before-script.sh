#!/bin/sh -xe

cd "$VAULT_DIR" || exit
terraform init -upgrade
terraform workspace select "$CLUSTER_NAME" || terraform workspace new "$CLUSTER_NAME"
terraform init -upgrade
terraform destroy --auto-approve
if [ "$CLUSTER_NAME" != "default" ]; then
	terraform workspace select default
	terraform workspace delete "$CLUSTER_NAME"
fi
cd -

wget https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl -O ~/kubectl
chmod +x ~/kubectl

# Remove all Applications to prevent ArgoCD to reconcile
~/kubectl -n argocd delete application --all

# Remove all Operators to ensure that it does not redeploy stuffs
~/kubectl -n cluster-operators delete deployments --all

# Remove all pods to release volume mounted with rshared propagation
~/kubectl delete daemonsets --all --all-namespaces
~/kubectl delete statefulsets --all --all-namespaces
~/kubectl delete deployments --all --all-namespaces
~/kubectl delete cronjobs --all --all-namespaces
~/kubectl delete jobs --all --all-namespaces
~/kubectl delete horizontalpodautoscaler --all --all-namespaces
~/kubectl delete service --all --all-namespaces

while test "$(~/kubectl get pods --all-namespaces | wc -l)" -ne 0; do
	echo Waiting for destruction of all pods
	sleep 3
done
