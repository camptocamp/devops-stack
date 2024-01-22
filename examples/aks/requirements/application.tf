locals {
  # You can add here any user that should be owner of the Enterprise Application. The key can be anything an is used for
  # identification on the for each below, the value must be a valid object ID on your Azure tenant.
  application_owners = {
    "${trimspace(data.azuread_group.admins.display_name)}" = data.azuread_group.admins.object_id,
  }
}

resource "azuread_application_registration" "default" {
  display_name = local.oidc_application_name

  group_membership_claims = ["SecurityGroup"]
}

resource "azuread_application_owner" "default" {
  for_each = local.application_owners

  application_id  = resource.azuread_application_registration.default.id
  owner_object_id = each.value
}

resource "azuread_application_api_access" "default" {
  application_id = resource.azuread_application_registration.default.id
  api_client_id  = "00000003-0000-0000-c000-000000000000"   # Microsoft Graph
  scope_ids      = ["e1fe6dd8-ba31-4d61-89e7-88639da4683d"] # User.Read
}

resource "azuread_application_optional_claims" "default" {
  application_id = resource.azuread_application_registration.default.id

  access_token {
    additional_properties = []
    essential             = false
    name                  = "groups"
  }
  id_token {
    additional_properties = []
    essential             = false
    name                  = "groups"
  }
}

resource "azuread_application_password" "default" {
  application_id = resource.azuread_application_registration.default.id
}

resource "azurerm_key_vault_secret" "aad_application_object_id" {
  name         = "${resource.azuread_application_registration.default.display_name}-application-object-id"
  value        = resource.azuread_application_registration.default.object_id
  key_vault_id = resource.azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "aad_application_client_id" {
  name         = "${resource.azuread_application_registration.default.display_name}-application-client-id"
  value        = resource.azuread_application_registration.default.client_id
  key_vault_id = resource.azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "aad_application_client_secret" {
  name         = "${resource.azuread_application_registration.default.display_name}-application-client-secret"
  value        = resource.azuread_application_password.default.value
  key_vault_id = resource.azurerm_key_vault.main.id
}
