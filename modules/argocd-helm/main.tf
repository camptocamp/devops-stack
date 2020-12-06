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
            oidc.default.clientSecret: ${var.client_secret}
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
