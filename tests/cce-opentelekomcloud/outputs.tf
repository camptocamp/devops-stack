output "kubeconfig" {
  sensitive = true
  value     = module.cluster.kubeconfig
}

output "keycloak_users" {
  sensitive = true
  value     = module.cluster.keycloak_users
}
