terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
    }
    argocd = {
      source = "oboukili/argocd"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
