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

output "minio_root_user_credentials" {
  value     = module.minio.minio_root_user_credentials
  sensitive = true
}

output "minio_loki_user" {
  value     = random_password.loki_secretkey.result
  sensitive = true
}
