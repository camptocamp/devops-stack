/* output "base_domain" {
  value = module.cluster.base_domain
}

output "argocd_auth_token" {
  sensitive = true
  value     = module.cluster.argocd_auth_token
}

output "argocd_server_admin_password" {
  sensitive = true
  value     = module.cluster.argocd_server_admin_password
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

output "argocd_url" {
  value = format("https://argocd.apps.%s.%s", var.cluster_name, module.cluster.base_domain)
}

output "grafana_url" {
  value = format("https://grafana.apps.%s.%s", var.cluster_name, module.cluster.base_domain)
}

output "prometheus_url" {
  value = format("https://prometheus.apps.%s.%s", var.cluster_name, module.cluster.base_domain)
}

output "alertmanager_url" {
  value = format("https://alertmanager.apps.%s.%s", var.cluster_name, module.cluster.base_domain)
}

output "grafana_admin_password" {
  sensitive = true
  value     = module.cluster.grafana_admin_password
}
*/
