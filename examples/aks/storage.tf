locals {
  storage_containers = [
    "loki",
    "thanos",
  ]
}

resource "azurerm_storage_account" "storage" {
  for_each = toset(local.storage_containers)

  name                            = format("%s%s", replace(local.common_resource_group, "-", ""), each.key)
  resource_group_name             = resource.azurerm_resource_group.main.name
  location                        = resource.azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "storage" {
  for_each = toset(local.storage_containers)

  name                 = "${each.key}-${local.common_resource_group}"
  storage_account_name = resource.azurerm_storage_account.storage[each.key].name
}
