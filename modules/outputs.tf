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
    client_certificate     = local.kubernetes_client_certificate                    
    client_key             = local.kubernetes_client_key                            
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

output "argocd_namespace" {
  value = module.argocd.argo_namespace
}

output "repo_url" {
  value = var.repo_url
}

output "target_revision" {
  value = var.target_revision
}
