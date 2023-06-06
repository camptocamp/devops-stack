# resource "azurerm_virtual_network" "this" {
#   name                = "devops-stack-vnet"
#   resource_group_name = azurerm_resource_group.default.name
#   location            = azurerm_resource_group.default.location
#   address_space       = ["10.1.0.0/16"]
# }

# resource "azurerm_subnet" "this" {
#   name                 = local.cluster_name
#   resource_group_name  = azurerm_resource_group.default.name
#   address_prefixes     = ["10.1.0.0/20"]
#   virtual_network_name = azurerm_virtual_network.this.name
# }
