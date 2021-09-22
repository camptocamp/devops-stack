provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = var.cluster_name
  location = "westus2" # cheapest location as of 22/09/2021
}

data "null_data_source" "resource_group" {
  inputs = {
    id   = azurerm_resource_group.this.id
    name = azurerm_resource_group.this.name
  }
}

resource "azurerm_virtual_network" "this" {
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = ["10.42.0.0/16"]
}

resource "azurerm_subnet" "this" {
  name                 = var.cluster_name
  resource_group_name  = azurerm_resource_group.this.name
  address_prefixes     = ["10.42.0.0/20"]
  virtual_network_name = azurerm_virtual_network.this.name
}

module "cluster" {
  source = "../../modules/aks/azure"

  cluster_name = var.cluster_name

  repo_url        = var.repo_url
  target_revision = var.target_revision

  resource_group_name = data.null_data_source.resource_group.outputs["name"]
  vnet_subnet_id      = azurerm_subnet.this.id
}
