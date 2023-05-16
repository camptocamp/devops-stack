locals {
  cluster_issuer   = "letsencrypt-staging"
  argocd_namespace = "argocd" # Argo CD is deployed by default inside the namespace `argocd` but we need to tell this to the other modules.
}
