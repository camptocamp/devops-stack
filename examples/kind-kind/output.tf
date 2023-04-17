output "argocd_auth_token" {
  value     = module.argocd_bootstrap.argocd_auth_token
  sensitive = true
}

output "keycloak_admin_credentials" {
  value     = module.keycloak.admin_credentials
  sensitive = true
}

output "keycloak_users" {
  value     = module.keycloak-config.devops_stack_users_passwords
  sensitive = true
}
