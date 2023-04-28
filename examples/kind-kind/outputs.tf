# TODO: is this needed ?
# output "argocd_auth_token" {
#   description = "" # TODO
#   value     = module.argocd_bootstrap.argocd_auth_token
#   sensitive = true
# }

output "kubernetes_kubeconfig" {
  description = "Configuration that can be copied into `.kube/config in order to access the cluster with `kubectl`."
  value       = module.kind.raw_kubeconfig
  sensitive   = true
}

output "keycloak_admin_credentials" {
  description = "Credentials for the administrator user of the Keycloak server."
  value       = module.keycloak.admin_credentials
  sensitive   = true
}

output "keycloak_users" {
  description = "Map containing the credentials of each created user."
  value       = module.oidc.devops_stack_users_passwords
  sensitive   = true
}

output "minio_root_user_credentials" {
  description = "Credentials for the administrator user of the MinIO server."
  value       = module.minio.minio_root_user_credentials
  sensitive   = true
}
