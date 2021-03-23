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

output "repo_url" {
  value = module.cluster.repo_url
}

output "target_revision" {
  value = module.cluster.target_revision
}

output "app_of_apps_values" {
  sensitive = true
  value     = module.cluster.app_of_apps_values
}

output "admin_password" {
  sensitive = true
  value     = module.cluster.admin_password
}

output "grafana_admin_password" {
  sensitive = true
  value = module.cluster.grafana_admin_password 
}
