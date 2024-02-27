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
    format("https://argocd.%s/auth/callback", trimprefix("${local.subdomain}.${module.aks.base_domain}", ".")),
    format("https://argocd.%s.%s/auth/callback", trimprefix("${local.subdomain}.${module.aks.cluster_name}", "."), module.aks.base_domain),
    format("https://grafana.%s/login/generic_oauth", trimprefix("${local.subdomain}.${module.aks.base_domain}", ".")),
    format("https://grafana.%s.%s/login/generic_oauth", trimprefix("${local.subdomain}.${module.aks.cluster_name}", "."), module.aks.base_domain),
    format("https://prometheus.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.base_domain}", ".")),
    format("https://prometheus.%s.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.cluster_name}", "."), module.aks.base_domain),
    format("https://alertmanager.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.base_domain}", ".")),
    format("https://alertmanager.%s.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.cluster_name}", "."), module.aks.base_domain),
    format("https://thanos-query.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.base_domain}", ".")),
    format("https://thanos-query.%s.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.cluster_name}", "."), module.aks.base_domain),
    format("https://thanos-bucketweb.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.base_domain}", ".")),
    format("https://thanos-bucketweb.%s.%s/oauth2/callback", trimprefix("${local.subdomain}.${module.aks.cluster_name}", "."), module.aks.base_domain),
  ]
}
