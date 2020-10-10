terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "2.3.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.2"
    }
  }
  required_version = ">= 0.13"
}
