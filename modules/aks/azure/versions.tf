terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "1.0.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
  }

  required_version = ">= 0.13"
}
