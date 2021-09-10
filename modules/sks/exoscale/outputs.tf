output "base_domain" {
  value = local.base_domain
}

output "jdoe_password" {
  description = "The password of a regular user jdoe."
  value     = random_password.jdoe_password.result
  sensitive = true
}

output "keycloak_admin_password" {
  description = "The password of Keycloak's admin user."
  value       = yamldecode(var.app_of_apps_values_overrides).apps.keycloak.enabled == false ? null : data.kubernetes_secret.keycloak_admin_password.data.ADMIN_PASSWORD
  sensitive   = true
}

output "nlb_ip_address" {
  value = exoscale_nlb.this.ip_address
}
