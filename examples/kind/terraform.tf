terraform {
  required_providers {
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
    vault = {
      source  = "hashicorp/vault"
      version = "~>3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}
