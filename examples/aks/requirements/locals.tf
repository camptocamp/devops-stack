locals {
  location               = "YOUR_LOCATION"
  base_domain            = "your.domain.here"
  default_key_vault      = "YOUR_KEY_VAULT_NAME"         # The name of the Key Vault with the Azure AD application credentials.
  default_resource_group = "YOUR_DEFAULT_RESOURCE_GROUP" # The default resource group where the Key Vault with the Azure AD application credentials will reside.
  oidc_application_name  = "YOUR_APPLICATION_NAME"       # The name of the Azure AD application that will be used for OIDC authentication.
  admins_group_object_id = "YOUR_CLUSTER_ADMINS_GROUP_OBJECT_ID"
}
