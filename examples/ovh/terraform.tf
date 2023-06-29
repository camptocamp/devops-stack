terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.31.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2"
    }

    argocd = {
      source  = "oboukili/argocd"
      version = "~> 4"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4"
    }
  }
}
