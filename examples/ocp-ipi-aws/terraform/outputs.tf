# terraform/outputs.tf

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

output "console_url" {
  value = module.cluster.console_url
}

output "kubeadmin_password" {
  value     = module.cluster.kubeadmin_password
  sensitive = true
}
