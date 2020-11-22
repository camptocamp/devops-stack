output "argocd_accounts_pipeline_tokens" {
  description = "The token created for the pipeline."
  value       = local.argocd_accounts_pipeline_tokens
}

output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = jwt_hashed_token.argocd.token
}
