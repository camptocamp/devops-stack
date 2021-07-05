output "node_resource_group" {
  value = module.cluster.node_resource_group
}

output "cluster_id" {
  value = module.cluster.aks_id
}

output "prometheus_user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.principal_id
}

output "kube_admin_config" {
  value = {
    client_key             = module.cluster.admin_client_key
    client_certificate     = module.cluster.admin_client_certificate
    cluster_ca_certificate = module.cluster.admin_cluster_ca_certificate
    host                   = module.cluster.admin_host
    username               = module.cluster.admin_username
    password               = module.cluster.admin_password
  }
}
