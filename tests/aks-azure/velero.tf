resource "random_uuid" "bucket_name" {}
resource "random_string" "storage_account_name" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_storage_account" "velero" {
  name                     = "velero${random_string.storage_account_name.result}"
  location                 = var.location
  resource_group_name      = var.resource_group
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "velero" {
  name                 = random_uuid.bucket_name.result
  storage_account_name = azurerm_storage_account.velero.name
}


