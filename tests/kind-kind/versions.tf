terraform {
  required_providers {
    argocd = {
      source = "oboukili/argocd"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
