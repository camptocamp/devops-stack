output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = jwt_hashed_token.argocd.token
}

output "argocd_server_admin_password" {
  description = "The ArgoCD admin password."
  sensitive   = true
  value       = random_password.argocd_server_admin.result
}

output "argo_namespace" {
  value = helm_release.argocd.metadata.0.namespace
}

output "argocd_domain" {
  value = local.argocd.domain
}
