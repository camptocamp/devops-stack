output "ingress_domain" {
  description = "The domain to use for accessing the applications."
  value       = "${local.cluster_name}.${local.base_domain}"
}

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
