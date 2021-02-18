output "base_domain" {
  value = module.cluster.base_domain
}

output "argocd_auth_token" {
  sensitive = true
  value     = module.cluster.argocd_auth_token
}

output "kubeconfig" {
  sensitive = true
  value     = module.cluster.kubeconfig
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
  value = format("https://argocd.apps.%s", module.cluster.base_domain)
}

output "grafana_url" {
  value = format("https://grafana.apps.%s", module.cluster.base_domain)
}

output "prometheus_url" {
  value = format("https://prometheus.apps.%s", module.cluster.base_domain)
}

output "alertmanager_url" {
  value = format("https://alertmanager.apps.%s", module.cluster.base_domain)
}

output "keycloak_url" {
  value = format("https://keycloak.apps.%s/auth/realms/kubernetes/account", module.cluster.base_domain)
}

output "admin_password" {
  sensitive = true
  value     = module.cluster.admin_password
}
