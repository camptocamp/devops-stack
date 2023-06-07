locals {
  platform_name = "example"
  cluster_name  = "blue"

  oidc = {
    issuer_url              = format("https://login.microsoftonline.com/%s/v2.0", data.azurerm_client_config.current.tenant_id)
    oauth_url               = format("https://login.microsoftonline.com/%s/oauth2/authorize", data.azurerm_client_config.current.tenant_id)
    token_url               = format("https://login.microsoftonline.com/%s/oauth2/token", data.azurerm_client_config.current.tenant_id)
    api_url                 = format("https://graph.microsoft.com/oidc/userinfo")
    client_id               = azuread_application.this.application_id
    client_secret           = azuread_application_password.this.value
    oauth2_proxy_extra_args = []
  }
}
