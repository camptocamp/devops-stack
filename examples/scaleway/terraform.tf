terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }

    argocd = {
      source  = "oboukili/argocd"
      version = "6.0.3"
    }
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}
