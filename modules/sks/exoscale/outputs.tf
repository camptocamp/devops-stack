locals {
  kubeconfig = yamldecode(module.cluster.kubeconfig)
}

output "cluster_name" {
  value = var.cluster_name
}

output "base_domain" {
  value = local.base_domain
}

output "nlb_ip_address" {
  value = exoscale_nlb.this.ip_address
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the SKS nodepool instances."
  value       = module.cluster.this_security_group_id
}

output "kubernetes_host" {
  value = local.kubeconfig.clusters.0.cluster.server
}

output "kubernetes_cluster_ca_certificate" {
  value = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
}

output "kubernetes_client_key" {
  value = base64decode(local.kubeconfig.users.0.user.client-key-data)
}

output "kubernetes_client_certificate" {
  value = base64decode(local.kubeconfig.users.0.user.client-certificate-data)
}

output "router_pool_id" {
  value = module.cluster.nodepools[var.router_nodepool].instance_pool_id
}
