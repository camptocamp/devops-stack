module "cluster" {
  source  = "Azure/aks/azurerm"
  version = "~> 6.0"

  kubernetes_version                = 1.25
  orchestrator_version              = 1.25
  prefix                            = local.cluster_name
  vnet_subnet_id                    = azurerm_subnet.this.id
  resource_group_name               = azurerm_resource_group.default.name
  azure_policy_enabled              = true
  network_plugin                    = "azure"
  private_cluster_enabled           = false
  rbac_aad_managed                  = true
  role_based_access_control_enabled = true
  log_analytics_workspace_enabled   = false
  sku_tier                          = "Free"
  agents_pool_name                  = "default"
  agents_labels                     = { "devops-stack/nodepool" : "default" }
  agents_count                      = 1
  agents_size                       = "Standard_D4s_v3"
  agents_max_pods                   = 150
  os_disk_size_gb                   = 128
  oidc_issuer_enabled               = true
}
