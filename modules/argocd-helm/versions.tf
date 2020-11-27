terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }
    jwt = {
      source  = "camptocamp/jwt"
      version = "0.0.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.6.0"
    }
  }
  required_version = ">= 0.13"
}
