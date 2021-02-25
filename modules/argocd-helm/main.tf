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

  argocd_chart = yamldecode(file("${path.module}/../../argocd/argocd/Chart.yaml")).dependencies.0
}

resource "time_static" "iat" {}

resource "random_uuid" "jti" {}

resource "random_string" "argocd_server_secretkey" {
  count = var.argocd_server_secretkey == null ? 1 : 0

  length  = 32
  special = false
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = local.argocd_chart.repository
  chart      = "argo-cd"
  version    = local.argocd_chart.version

  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true
  timeout           = 10800

  values = [
    yamlencode(yamldecode(file("${path.module}/../../argocd/argocd/values.yaml")).argo-cd),
    <<EOT
    configs:
      secret:
        extra:
          oidc.default.clientSecret: ${var.oidc.client_secret}
          accounts.pipeline.tokens: '${local.argocd_accounts_pipeline_tokens}'
          server.secretkey: ${var.argocd_server_secretkey == null ? random_string.argocd_server_secretkey.0.result : var.argocd_server_secretkey}
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
        argocd_server_secretkey         = var.argocd_server_secretkey == null ? random_string.argocd_server_secretkey.0.result : var.argocd_server_secretkey
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

resource "null_resource" "wait_for_app_of_apps" {
  depends_on = [
    helm_release.app_of_apps
  ]

  provisioner "local-exec" {
    command     = "while ! KUBECONFIG=<(echo \"$KUBECONFIG_CONTENT\") argocd app wait apps --sync --health --timeout 30; do echo Retry; done"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      ARGOCD_OPTS        = "--plaintext --port-forward --port-forward-namespace argocd"
      KUBECONFIG_CONTENT = var.kubeconfig
      ARGOCD_AUTH_TOKEN  = jwt_hashed_token.argocd.token
    }
  }
}

resource "random_password" "oauth2_cookie_secret" {
  length  = 16
  special = false
}
