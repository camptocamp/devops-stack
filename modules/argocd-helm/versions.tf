terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    jwt = {
      source  = "camptocamp/jwt"
      version = "~> 0.0.3"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
    time = {
      source = "hashicorp/time"
    }
  }
  required_version = ">= 0.13"
}
