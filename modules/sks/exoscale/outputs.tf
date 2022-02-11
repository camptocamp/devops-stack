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

output "kubernetes" {
  value     = local.kubernetes
  sensitive = true
}

output "router_pool_id" {
  value = local.router_pool_id
}
