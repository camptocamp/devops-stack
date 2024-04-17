locals {
  # Parameters for the resources that are created outside this code, but still on the Azure subscription where the DevOps Stack will be deployed.
  default_resource_group         = "YOUR_DEFAULT_RESOURCE_GROUP" # The default resource group where the Key Vault with the Azure AD application credentials is located.
  default_key_vault              = "YOUR_KEY_VAULT_NAME"         # The name of the Key Vault with the Azure AD application credentials.
  oidc_application_name          = "YOUR_APPLICATION_NAME"       # The name of the Azure AD application that will be used for OIDC authentication.  cluster_admins_group_object_id = "38a1908d-0ccd-4acc-99d5-7f0228289752"
  cluster_admins_group_object_id = "YOUR_CLUSTER_ADMINS_GROUP_OBJECT_ID"

  # Parameters used for this deployment of the DevOps Stack.
  common_resource_group    = "YOUR_COMMON_RESOURCE_GROUP" # The resource group where the common resources will reside. Must be unique for each DevOps Stack deployment in a single Azure subscription. 
  location                 = "YOUR_LOCATION"
  kubernetes_version       = "1.28"
  sku_tier                 = "Standard"
  cluster_name             = "YOUR_CLUSTER_NAME" # Must be unique for each DevOps Stack deployment in a single Azure subscription.
  base_domain              = "your.domain.here"  # Must match a DNS zone in the Azure subscription where you are deploying the DevOps Stack.
  subdomain                = "apps"
  activate_wildcard_record = true
  cluster_issuer           = module.cert-manager.cluster_issuers.staging
  letsencrypt_issuer_email = "YOUR_EMAIL_ADDRESS"
  enable_service_monitor   = false # Can be enabled after the first bootstrap.
  app_autosync             = true ? { allow_empty = false, prune = true, self_heal = true } : {}

  # The virtual network CIDR must be unique for each DevOps Stack deployment in a single Azure subscription.
  virtual_network_cidr = "10.1.0.0/16"

  # Automatic subnets IP range calculation, splitting the virtual_network_cidr above into multiple subnets.
  cluster_subnet = cidrsubnet(local.virtual_network_cidr, 6, 0)

  # Local containing all the OIDC definitions required by the DevOps Stack modules.
  oidc = {
    issuer_url    = format("https://login.microsoftonline.com/%s/v2.0", data.azuread_client_config.current.tenant_id)
    oauth_url     = format("https://login.microsoftonline.com/%s/oauth2/authorize", data.azuread_client_config.current.tenant_id)
    token_url     = format("https://login.microsoftonline.com/%s/oauth2/token", data.azuread_client_config.current.tenant_id)
    api_url       = format("https://graph.microsoft.com/oidc/userinfo")
    client_id     = data.azurerm_key_vault_secret.aad_application_client_id.value
    client_secret = data.azurerm_key_vault_secret.aad_application_client_secret.value
    oauth2_proxy_extra_args = local.cluster_issuer != "letsencrypt-prod" ? [
      "--insecure-oidc-skip-issuer-verification=true",
      "--ssl-insecure-skip-verify=true",
    ] : []
  }
}
