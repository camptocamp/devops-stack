data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  name     = local.default_resource_group
  location = local.location
}

resource "azurerm_key_vault" "main" {
  name                = local.default_key_vault
  location            = resource.azurerm_resource_group.default.location
  resource_group_name = resource.azurerm_resource_group.default.name
  sku_name            = "standard"
  tenant_id           = data.azuread_client_config.current.tenant_id

  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
  enabled_for_disk_encryption = true

  depends_on = [
    resource.azurerm_resource_group.default,
    resource.azuread_application_registration.default,
  ]
}

data "azuread_group" "admins" {
  object_id = local.admins_group_object_id
}

resource "azurerm_role_assignment" "admins" {
  for_each = toset([
    "Key Vault Reader",       # Permissions required to read Key Vault secrets
    "Key Vault Secrets User", # Permissions required to read contents of Key Vault secrets
  ])
  principal_id         = data.azuread_group.admins.object_id
  role_definition_name = each.value
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}
