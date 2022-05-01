terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.22.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5.1"
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
      version = "~> 2.11.0"
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
  required_version = ">= 1.1.9"
}
