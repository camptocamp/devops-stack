locals {
  base_domain                       = var.base_domain
  kubernetes_host                   = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config.0.host
  kubernetes_username               = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config.0.username
  kubernetes_password               = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config.0.password
  kubernetes_client_certificate     = base64decode(azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config.0.client_certificate)
  kubernetes_client_key             = base64decode(azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config.0.client_key)
  kubernetes_cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config.0.cluster_ca_certificate)

  azure_dns_label_name = format("%s-%s", var.cluster_name, replace(var.base_domain, ".", "-"))
  # kubeconfig           = data.azurerm_kubernetes_cluster.cluster.kube_admin_config_raw

  azureidentities = { for v in var.azureidentities :
    format("%s.%s", v.namespace, v.name) => {
      name         = v.name
      namespace    = v.namespace
      resource_id  = azurerm_user_assigned_identity.this[format("%s.%s", v.namespace, v.name)].id
      client_id    = azurerm_user_assigned_identity.this[format("%s.%s", v.namespace, v.name)].client_id
      principal_id = azurerm_user_assigned_identity.this[format("%s.%s", v.namespace, v.name)].principal_id
    }
  }

  namespaces = merge(
    { for i in distinct(var.azureidentities[*].namespace) : i => null },
    var.app_node_selectors
  )
  oidc_defaults = var.oidc != null ? var.oidc : {
    issuer_url              = format("https://login.microsoftonline.com/%s/v2.0", data.azurerm_client_config.current.tenant_id)
    oauth_url               = format("https://login.microsoftonline.com/%s/oauth2/authorize", data.azurerm_client_config.current.tenant_id)
    token_url               = format("https://login.microsoftonline.com/%s/oauth2/token", data.azurerm_client_config.current.tenant_id)
    api_url                 = format("https://graph.microsoft.com/oidc/userinfo")
    client_id               = azuread_application.oauth2_apps.0.application_id
    client_secret           = azuread_application_password.oauth2_apps.0.value
    oauth2_proxy_extra_args = []
  }
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    username               = local.kubernetes_username
    password               = local.kubernetes_password
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  username               = local.kubernetes_username
  password               = local.kubernetes_password
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

provider "azurerm" {
  features {}
}