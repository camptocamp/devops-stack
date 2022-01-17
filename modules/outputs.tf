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

output "kubernetes" {
  value = {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}

output "argocd_server" {
  description = "The URL of the ArgoCD server."
  value       = format("argocd.apps.%s.%s:443", var.cluster_name, local.base_domain)
}

output "argocd_server_admin_password" {
  description = "The ArgoCD admin password."
  sensitive   = true
  value       = module.argocd.argocd_server_admin_password
}

output "argocd_server_secretkey" {
  description = "ArgoCD Server Secert Key to avoid regenerate token on redeploy."
  sensitive   = true
  value       = module.argocd.argocd_server_secretkey
}

output "argocd_accounts_pipeline_tokens" {
  description = "The ArgoCD accounts pipeline tokens."
  sensitive   = true
  value       = module.argocd.argocd_accounts_pipeline_tokens
}

output "argocd_namespace" {
  value = module.argocd.argo_namespace
}

output "argocd_domain" {
  value = module.argocd.argocd_domain
}

output "repo_url" {
  value = var.repo_url
}

output "target_revision" {
  value = var.target_revision
}
