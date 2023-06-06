terraform {
  backend "azurerm" {
    resource_group_name  = "state-file"
    storage_account_name = "dstackazstate"
    container_name       = "state"
    key                  = "tfstate"
  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2"
    }
    jwt = {
      source  = "camptocamp/jwt"
      version = ">= 0.0.3"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2"
    }
    argocd = {
      source = "oboukili/argocd"
      version = "~> 4"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = ">= 0.9"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3"
    }
  }

  required_version = ">= 1.2.0"
}
