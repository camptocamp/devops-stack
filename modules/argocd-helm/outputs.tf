output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = jwt_hashed_token.argocd.token
}

output "app_of_apps_values" {
  description = "App of Apps values"
  sensitive   = true
  value       = helm_release.app_of_apps.values
}

output "repositories_public_keys_openssh" {
  description = "Public key of SSH keys allowed to access repositories"

  value = tomap({
    for repository in var.repositories :
    repository => tls_private_key.repositories[repository].public_key_openssh
  })
}
