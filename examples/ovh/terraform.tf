terraform {
  required_providers {

    helm = {
      source  = "hashicorp/helm"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
    }

    ovh = {
      source  = "ovh/ovh"
    }

    argocd = {
      source = "oboukili/argocd"
    }
  }
}

