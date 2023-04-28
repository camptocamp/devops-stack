terraform {
  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4"
    }
  }
}
