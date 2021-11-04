data "local_file" "sshkey" {
  filename = var.public_ssh_file
}

resource "azurerm_resource_group" "this" {
  name     = var.cluster_name
  location = var.location
}

module "network" {
  source  = "Azure/network/azurerm"
  version = "3.2.1"

  resource_group_name = azurerm_resource_group.this.name
  address_space       = "10.1.0.0/16"
  subnet_prefixes     = ["10.1.0.0/22"]
  vnet_name           = format("%s-network", var.cluster_name)
  subnet_names        = ["internal"]
  tags                = {}
  depends_on          = [azurerm_resource_group.this]
}

module "cluster" {
  source = "../../modules/aks/azure"

  vnet_subnet_id      = module.network.vnet_subnets[0]
  resource_group_name = azurerm_resource_group.this.name
  base_domain         = var.base_domain
  public_ssh_key      = data.local_file.sshkey.content
  cluster_name        = var.cluster_name
  velero = {
    storage        = azurerm_storage_account.velero.name
    container      = azurerm_storage_container.velero.name
    resource_group = azurerm_resource_group.this.name
  }
}
