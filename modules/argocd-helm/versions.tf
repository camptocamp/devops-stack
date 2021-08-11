terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    jwt = {
      source  = "camptocamp/jwt"
      version = ">= 0.0.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "~> 0.9"
    }
  }
  required_version = ">= 0.13"
}
