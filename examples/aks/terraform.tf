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
      version = "~> 3"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 6"
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

# The providers configurations below depend on the output of some of the modules declared on other *tf files.
# However, for clarity and ease of maintenance we grouped them all together in this section.

provider "kubernetes" {
  host                   = module.aks.kubernetes_host
  username               = module.aks.kubernetes_username
  password               = module.aks.kubernetes_password
  cluster_ca_certificate = module.aks.kubernetes_cluster_ca_certificate
  client_certificate     = module.aks.kubernetes_client_certificate
  client_key             = module.aks.kubernetes_client_key
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kubernetes_host
    username               = module.aks.kubernetes_username
    password               = module.aks.kubernetes_password
    cluster_ca_certificate = module.aks.kubernetes_cluster_ca_certificate
    client_certificate     = module.aks.kubernetes_client_certificate
    client_key             = module.aks.kubernetes_client_key
  }
}

provider "argocd" {
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace
  insecure                    = true
  plain_text                  = true

  kubernetes {
    host                   = module.aks.kubernetes_host
    username               = module.aks.kubernetes_username
    password               = module.aks.kubernetes_password
    cluster_ca_certificate = module.aks.kubernetes_cluster_ca_certificate
    client_certificate     = module.aks.kubernetes_client_certificate
    client_key             = module.aks.kubernetes_client_key
  }
}
