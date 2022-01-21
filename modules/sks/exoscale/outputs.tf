output "base_domain" {
  value = local.base_domain
}

output "kubernetes" {
  value = local.kubernetes
}

output "keycloak_users" {
  value     = { for username, infos in local.keycloak_user_map : username => lookup(infos, "password") }
  sensitive = true
}

output "keycloak_admin_password" {
  description = "The password of Keycloak's admin user."
  value       = data.kubernetes_secret.keycloak_admin_password.data != null ? data.kubernetes_secret.keycloak_admin_password.data.ADMIN_PASSWORD : null
  sensitive   = true
}

output "nlb_ip_address" {
  value = exoscale_nlb.this.ip_address
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the SKS nodepool instances."
  value       = module.cluster.this_security_group_id
}
