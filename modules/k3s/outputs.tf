output "base_domain" {
  value = local.base_domain
}

output "oidc" {
  value = local.oidc
}

output "keycloak_users" {
  value     = { for username, infos in local.keycloak_user_map : username => lookup(infos, "password") }
  sensitive = true
}

#output "keycloak_admin_password" {
#  description = "The password of Keycloak's admin user."
#  value       = data.kubernetes_secret.keycloak_admin_password.data.ADMIN_PASSWORD
#  sensitive   = true
#}
