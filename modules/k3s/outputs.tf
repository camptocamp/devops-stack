output "base_domain" {
  value = local.base_domain
}

output "oidc" {
  value = local.oidc
}

output "kubernetes" {
  value = {
    host                   = local.kubernetes_host
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
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
