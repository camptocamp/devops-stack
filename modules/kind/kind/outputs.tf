output "base_domain" {
  value = local.base_domain
}

output "jdoe_password" {
  description = "The password of a regular user jdoe."
  value       = random_password.jdoe_password.result
  sensitive   = true
}

output "keycloak_admin_password" {
  description = "The password of Keycloak's admin user."
  value       = data.kubernetes_secret.keycloak_admin_password.data.ADMIN_PASSWORD
  sensitive   = true
}
