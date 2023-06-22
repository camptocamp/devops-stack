terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }

    argocd = {
      source  = "oboukili/argocd"
      version = "4.0.0"
    }
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}
