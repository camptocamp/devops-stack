output "base_domain" {
  value = local.base_domain
}

output "admin_password" {
  value     = random_password.admin_password.result
  sensitive = true
}

output "keycloak_admin_password" {
  description = "The password of Keycloak's admin user."
  value       = data.kubernetes_secret.keycloak_admin_password.data.ADMIN_PASSWORD
  sensitive   = true
}
