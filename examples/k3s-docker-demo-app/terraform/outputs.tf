output "argocd_auth_token" {
  sensitive = true
  value     = module.cluster.argocd_auth_token
}

output "kubeconfig" {
  sensitive = true
  value     = module.cluster.kubeconfig
}

output "argocd_server" {
  value = module.cluster.argocd_server
}

output "grafana_admin_password" {
  sensitive = true
  value     = module.cluster.grafana_admin_password
}

output "admin_password" {
  sensitive = true
  value     = module.cluster.admin_password
}
