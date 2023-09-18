resource "azurerm_resource_group" "state" {
  name     = "state-file"
  location = "France Central"
}

resource "azurerm_storage_account" "state" {
  name                     = "dstackazstate"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state" {
  name                 = "state"
  storage_account_name = azurerm_storage_account.state.name
}
