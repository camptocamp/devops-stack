output "minio_root_user_credentials" {
  value     = module.minio.root_user_credentials
  sensitive = true
}

output "keycloak_admin_credentials" {
  value     = module.oidc.admin_credentials
  sensitive = true
}

output "keycloak_users" {
  value     = module.oidc_bootstrap.devops_stack_users_passwords
  sensitive = true
}
