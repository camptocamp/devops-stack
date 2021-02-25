resource "aws_cognito_user_pool_client" "client" {
  count = var.oidc == null ? 1 : 0

  name = format("client-%s", var.cluster_name)

  user_pool_id = var.cognito_user_pool_id

  allowed_oauth_flows = [
    "code",
  ]

  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile",
  ]

  supported_identity_providers = [
    "COGNITO",
  ]

  generate_secret = true

  allowed_oauth_flows_user_pool_client = true

  callback_urls = [
    format("https://argocd.apps.%s.%s/auth/callback", var.cluster_name, var.base_domain),
    format("https://grafana.apps.%s.%s/login/generic_oauth", var.cluster_name, var.base_domain),
    format("https://prometheus.apps.%s.%s/oauth2/callback", var.cluster_name, var.base_domain),
    format("https://alertmanager.apps.%s.%s/oauth2/callback", var.cluster_name, var.base_domain),
  ]
}
