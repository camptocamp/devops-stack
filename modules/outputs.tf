output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = module.argocd.argocd_auth_token
  sensitive   = true
}

output "kubeconfig" {
  description = "The content of the KUBECONFIG file."
  value       = local.kubeconfig
  sensitive   = true
}

output "argocd_server" {
  description = "The URL of the ArgoCD server."
  value       = format("argocd.apps.%s.%s:443", var.cluster_name, local.base_domain)
}

output "repo_url" {
  value = var.repo_url
}

output "target_revision" {
  value = var.target_revision
}

output "app_of_apps_values" {
  value = module.argocd.app_of_apps_values
}
