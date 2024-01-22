data "azurerm_key_vault" "default" {
  name                = local.default_key_vault
  resource_group_name = local.default_resource_group
}

data "azurerm_key_vault_secret" "aad_application_object_id" {
  key_vault_id = data.azurerm_key_vault.default.id
  name         = "${local.oidc_application_name}-application-object-id"
}
data "azurerm_key_vault_secret" "aad_application_client_id" {
  key_vault_id = data.azurerm_key_vault.default.id
  name         = "${local.oidc_application_name}-application-client-id"
}
data "azurerm_key_vault_secret" "aad_application_client_secret" {
  key_vault_id = data.azurerm_key_vault.default.id
  name         = "${local.oidc_application_name}-application-client-secret"
}

resource "azuread_application_redirect_uris" "redirect_uris" {
  application_id = format("/applications/%s", data.azurerm_key_vault_secret.aad_application_object_id.value)
  type           = "Web"

  redirect_uris = [
    format("https://argocd.apps.%s.%s/auth/callback", module.aks.cluster_name, module.aks.base_domain),
    format("https://grafana.apps.%s.%s/login/generic_oauth", module.aks.cluster_name, module.aks.base_domain),
    format("https://prometheus.apps.%s.%s/oauth2/callback", module.aks.cluster_name, module.aks.base_domain),
    format("https://alertmanager.apps.%s.%s/oauth2/callback", module.aks.cluster_name, module.aks.base_domain),
    format("https://thanos-bucketweb.apps.%s.%s/oauth2/callback", module.aks.cluster_name, module.aks.base_domain),
    format("https://thanos-query.apps.%s.%s/oauth2/callback", module.aks.cluster_name, module.aks.base_domain),
  ]
}
