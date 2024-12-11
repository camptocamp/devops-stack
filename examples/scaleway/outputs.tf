output "kubeconfig_file" {
  sensitive = true
  value     = module.scaleway.kubeconfig_file
}

output "base_domain" {
  value = module.scaleway.base_domain
}

output "ca" {
  value     = module.scaleway.kubeconfig[0].cluster_ca_certificate
  sensitive = true
}

output "passwords" {
  sensitive = true
  value     = module.authorization_with_keycloak.devops_stack_users_passwords
}
