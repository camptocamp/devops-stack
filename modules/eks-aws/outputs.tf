# Common outputs
output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = module.argocd.argocd_auth_token
}

output "kubeconfig" {
  value = local.kubeconfig
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
output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.cluster.cluster_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.cluster.cluster_oidc_issuer_url
}

output "worker_security_group_id" {
  description = "Security group ID attached to the EKS workers."
  value       = module.cluster.worker_security_group_id
}

output "worker_iam_role_name" {
  description = "default IAM role name for EKS worker groups"
  value       = module.cluster.worker_iam_role_name
}

output "kubernetes_host" {
  value = local.kubernetes_host
}

output "kubernetes_cluster_ca_certificate" {
  value = local.kubernetes_cluster_ca_certificate
}

output "kubernetes_token" {
  value = local.kubernetes_token
}
