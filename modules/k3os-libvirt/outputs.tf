# Common outputs
output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = module.argocd.argocd_auth_token
}

output "kubeconfig" {
  value = module.cluster.kubeconfig
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

# Specific outputs
output "base_domain" {
  value = local.base_domain
}

output "kubernetes_host" {
  value = local.kubernetes_host
}

output "kubernetes_username" {
  value = local.kubernetes_username
}

output "kubernetes_password" {
  value = local.kubernetes_password
}

output "kubernetes_cluster_ca_certificate" {
  value = local.kubernetes_cluster_ca_certificate
}

output "admin_password" {
  value = random_password.admin_password.result
}
