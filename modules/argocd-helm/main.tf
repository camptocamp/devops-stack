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
  timeout           = 10800

  values = [
    file("${path.module}/../../argocd/argocd/values.yaml"),
    <<EOT
    argo-cd:
      configs:
        secret:
          extra:
            oidc.default.clientSecret: ${var.oidc.client_secret}
            accounts.pipeline.tokens: '${local.argocd_accounts_pipeline_tokens}'
    EOT
  ]
}

data "kubernetes_secret" "argocd_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = helm_release.argocd.namespace
  }
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
        repo_url                        = var.repo_url
        target_revision                 = var.target_revision
        argocd_accounts_pipeline_tokens = local.argocd_accounts_pipeline_tokens
        extra_apps                      = var.extra_apps
        cluster_name                    = var.cluster_name
        base_domain                     = var.base_domain
        cluster_issuer                  = var.cluster_issuer
        oidc                            = local.oidc
        cookie_secret                   = random_password.oauth2_cookie_secret.result
        minio                           = local.minio
        loki                            = local.loki
        efs_provisioner                 = local.efs_provisioner
        argocd                          = local.argocd
        keycloak                        = local.keycloak
        grafana                         = local.grafana
        prometheus                      = local.prometheus
        alertmanager                    = local.alertmanager
        metrics_archives                = local.metrics_archives
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

