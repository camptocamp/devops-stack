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

output "vault_dev_root_token" {
  description = "Vault dev mode root token for authentication" # Isn't the output name explicit enough ?
  value       = random_password.vault_dev_root_token.result
  sensitive   = true
}
