terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "2.15.0"
    }
  }
  required_version = ">= 0.13"
}
