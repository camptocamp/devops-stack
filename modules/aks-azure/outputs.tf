# Common outputs
output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = module.argocd.argocd_auth_token
}

output "kubeconfig" {
  value = data.azurerm_kubernetes_cluster.cluster.kube_admin_config_raw
}

output "repo_url" {
  value = var.repo_url
}

output "target_revision" {
  value = var.target_revision
}

output "app_of_apps_values" {
  value = helm_release.app_of_apps.values
}

output "node_resource_group" {
  value = module.cluster.node_resource_group
}
