output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = jwt_hashed_token.argocd.token
}

output "app_of_apps_values" {
  description = "App of Apps values"
  sensitive   = true
  value       = helm_release.app_of_apps.values
}

output "argocd_server_admin_password" {
  description = "The ArgoCD admin password."
  sensitive   = true
  value       = random_password.argocd_server_admin.result
}

output "loki_creds" {
  description = "LogCLI basic auth password."
  sensitive = true
  value = {
    username = "loki"
    password = random_password.loki_basic_auth_password.result
  }
}
