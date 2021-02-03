output "node_resource_group" {
  value = module.cluster.node_resource_group
}

output "kube_prometheus_stack_prometheus_user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.principal_id
}
