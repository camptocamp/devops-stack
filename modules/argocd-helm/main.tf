locals {
  jwt_token_payload = {
    jti = random_uuid.jti.result
    iat = time_static.iat.unix
    iss = "argocd"
    nbf = time_static.iat.unix
    sub = "pipeline"
  }

  argocd_accounts_pipeline_tokens = jsonencode(
    [
      {
        id  = random_uuid.jti.result
        iat = time_static.iat.unix
      }
    ]
  )
}

resource "time_static" "iat" {}

resource "random_uuid" "jti" {}

resource "helm_release" "argocd" {
  name              = "argocd"
  chart             = "${path.module}/../../argocd/argocd"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    file("${path.module}/../../argocd/argocd/values.yaml"),
    <<EOT
    argo-cd:
      configs:
        secret:
          extra:
            accounts.pipeline.tokens: '${local.argocd_accounts_pipeline_tokens}'
    EOT
  ]
}

data "kubernetes_secret" "argocd_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = helm_release.argocd.namespace
  }

  depends_on = [
    helm_release.argocd,
  ]
}

resource "jwt_hashed_token" "argocd" {
  algorithm   = "HS256"
  secret      = lookup(data.kubernetes_secret.argocd_secret.data, "server.secretkey")
  claims_json = jsonencode(local.jwt_token_payload)
}

resource "helm_release" "app_of_apps" {
  name              = "app-of-apps"
  chart             = "${path.module}/../../argocd/app-of-apps"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = concat([
    templatefile("${path.module}/../../argocd/app-of-apps/values.tmpl.yaml",
      {
        repo_url                         = var.repo_url
        target_revision                  = var.target_revision
        argocd_accounts_pipeline_tokens  = local.argocd_accounts_pipeline_tokens
        extra_apps                       = var.extra_apps
        cluster_name                     = var.cluster_name
        base_domain                      = var.base_domain
        cluster_issuer                   = var.cluster_issuer
        oidc_issuer_url                  = var.oidc_issuer_url
        oauth2_oauth_url                 = var.oauth2_oauth_url
        oauth2_token_url                 = var.oauth2_token_url
        oauth2_api_url                   = var.oauth2_api_url
        client_id                        = var.client_id
        client_secret                    = var.client_secret
        cookie_secret                    = random_password.oauth2_cookie_secret.result
        admin_password                   = var.admin_password
        minio_access_key                 = var.minio_access_key
        minio_secret_key                 = var.minio_secret_key
        loki_bucket_name                 = var.loki_bucket_name,
        enable_efs                       = var.enable_efs
        enable_keycloak                  = var.enable_keycloak
        enable_olm                       = var.enable_olm
        enable_minio                     = var.enable_minio
        oauth2_proxy_extra_args          = var.oauth2_proxy_extra_args 
        grafana_generic_oauth_extra_args = var.grafana_generic_oauth_extra_args
      }
    )],
    var.app_of_apps_values_overrides,
  )

  depends_on = [
    helm_release.argocd
  ]
}

resource "random_password" "oauth2_cookie_secret" {
  length  = 16
  special = false
}

