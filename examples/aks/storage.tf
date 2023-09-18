resource "random_string" "storage_account_name" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_storage_account" "this" {
  name                     = "dsstore${random_string.storage_account_name.result}"
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "logs" {
  name                 = "logs"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_container" "metrics" {
  name                 = "metrics"
  storage_account_name = azurerm_storage_account.this.name
}
