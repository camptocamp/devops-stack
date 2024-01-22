terraform {
  backend "azurerm" {
    # All these resources must exist before Terraform can be initialized.
    resource_group_name  = "RG_NAME"                # The Resource Group's name where the Storage Account for the Terraform state exists.
    storage_account_name = "STORAGE_ACCOUNT_NAME"   # The Storage Account's name where the Terraform state will be stored.
    container_name       = "STORAGE_CONTAINER_NAME" # The name of the Storage Container where the Terraform state will be stored.
    key                  = "TF_STATE_NAME"          # The name of the Terraform state file.
    use_azuread_auth     = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "YOUR_SUBSCRIPTION_ID"
  tenant_id       = "YOUR_TENANT_ID"
}

provider "azuread" {
  tenant_id = "YOUR_TENANT_ID"
}
