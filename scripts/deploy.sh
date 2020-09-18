#!/bin/sh -x

# Install ArgoCD if not present
if test $(kubectl -n argocd get pods --selector "app.kubernetes.io/name=argocd-server" --output=name|wc -l) -eq 0; then
  helm dependency update argocd/argocd
  kubectl create namespace argocd || true
  helm template --include-crds argocd argocd/argocd \
    --set bootstrap=true \
    --namespace argocd | kubectl $KUBECTL_COMMAND -n argocd -f -
  kubectl -n argocd wait $(kubectl -n argocd get pods --selector "app.kubernetes.io/name=argocd-server" --output=name) --for=condition=Ready --timeout=-1s
fi
