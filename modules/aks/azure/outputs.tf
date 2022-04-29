output "base_domain" {
  value = local.base_domain
}

output "node_resource_group" {
  value = module.cluster.node_resource_group
}

output "cluster_id" {
  value = module.cluster.aks_id
}

output "kube_admin_config" {
  value = {
    client_key             = local.kubernetes_client_key
    client_certificate     = local.kubernetes_client_certificate
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
    host                   = local.kubernetes_host
    username               = local.kubernetes_username
    password               = local.kubernetes_password
  }
}

output "kubelet_identity" {
  value = module.cluster.kubelet_identity
}
