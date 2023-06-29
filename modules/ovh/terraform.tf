terraform {
  required_providers {
    ovh = {
      source = "ovh/ovh"
      version = "~> 0.25.0"
    }

    argocd = {
      source = "oboukili/argocd"
    }
  }
}
