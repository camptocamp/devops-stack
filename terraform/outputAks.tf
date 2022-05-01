output "base_domain" {
  value = local.base_domain
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.node_resource_group
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.id
}

output "prometheus_user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.principal_id
}

# output "kube_admin_config" {
#   value = {
#     client_key             = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.admin_client_key
#     client_certificate     = module.cluster.admin_client_certificate
#     cluster_ca_certificate = module.cluster.admin_cluster_ca_certificate
#     host                   = module.cluster.admin_host
#     username               = module.cluster.admin_username
#     password               = module.cluster.admin_password
#   }
# }

# output "client_certificate" {
#   value = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config.0.client_certificate
# }

output "kube_config" {
  value     = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_config_raw
  sensitive = true
}

output "azureidentities" {
  description = "Azure User Assigned Identities created"
  value       = local.azureidentities
}

output "namespaces" {
  value = local.namespaces
}

output "kubelet_admin_identity" {
  value = azurerm_kubernetes_cluster.mgmt-bootstrap-resources.kube_admin_config_raw
}
