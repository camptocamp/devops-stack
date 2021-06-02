output "node_resource_group" {
  value = module.cluster.node_resource_group
}

output "cluster_id" {
  value = module.cluster.aks_id
}

output "prometheus_user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.principal_id
}
