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

  argocd_server_secretkey = var.argocd_server_secretkey == null ? random_string.argocd_server_secretkey.result : var.argocd_server_secretkey

  app_of_apps_values = concat([
    templatefile("${path.module}/../../argocd/app-of-apps/values.tmpl.yaml",
      {
        repo_url                        = var.repo_url
        target_revision                 = var.target_revision
        argocd_accounts_pipeline_tokens = local.argocd_accounts_pipeline_tokens
        argocd_server_secretkey         = local.argocd_server_secretkey
        extra_apps                      = var.extra_apps
        cluster_name                    = var.cluster_name
        base_domain                     = var.base_domain
        cluster_issuer                  = var.cluster_issuer
        oidc                            = local.oidc
        cookie_secret                   = random_password.oauth2_cookie_secret.result
        minio                           = local.minio
        loki                            = local.loki
        traefik                         = local.traefik
        efs_provisioner                 = local.efs_provisioner
        argocd                          = local.argocd
        keycloak                        = local.keycloak
        grafana                         = local.grafana
        prometheus                      = local.prometheus
        alertmanager                    = local.alertmanager
        metrics_server                  = local.metrics_server
        metrics_archives                = local.metrics_archives
        cert_manager                    = local.cert_manager
        kube_prometheus_stack           = local.kube_prometheus_stack
      }
    )],
    var.app_of_apps_values_overrides,
  )

  argocd_values = compact([
    yamlencode(yamldecode(local.app_of_apps_values.0).argo-cd),
    local.app_of_apps_values.1 == "" ? "" : try(yamlencode(yamldecode(local.app_of_apps_values.1).argo-cd), ""),
    local.app_of_apps_values.2 == "" ? "" : try(yamlencode(yamldecode(local.app_of_apps_values.2).argo-cd), ""),
  ])

  argocd_opts = (contains(try(yamldecode(local.argocd_values.0).server.extraArgs, []), "--insecure") || contains(try(yamldecode(local.argocd_values.1).server.extraArgs, []), "--insecure") || contains(try(yamldecode(local.argocd_values.2).server.extraArgs, []), "--insecure")) ? "--plaintext --port-forward --port-forward-namespace argocd" : "--port-forward --port-forward-namespace argocd"
}

resource "time_static" "iat" {}

resource "random_uuid" "jti" {}

resource "random_string" "argocd_server_secretkey" {
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
  values            = local.argocd_values
}

resource "jwt_hashed_token" "argocd" {
  algorithm   = "HS256"
  secret      = local.argocd_server_secretkey
  claims_json = jsonencode(local.jwt_token_payload)
}

resource "helm_release" "app_of_apps" {
  name              = "app-of-apps"
  chart             = "${path.module}/../../argocd/app-of-apps"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true
  values            = local.app_of_apps_values

  depends_on = [
    helm_release.argocd
  ]
}

resource "null_resource" "wait_for_app_of_apps" {
  count = var.wait_for_app_of_apps ? 1 : 0

  depends_on = [
    helm_release.app_of_apps
  ]

  provisioner "local-exec" {
    command = "KUBECONFIG=$(mktemp /tmp/kubeconfig.XXXXXX) ; echo \"$KUBECONFIG_CONTENT\" > \"$KUBECONFIG\" ; export KUBECONFIG ; while ! argocd app wait apps --sync --health --timeout 30; do echo Retry; done ; rm \"$KUBECONFIG\""

    environment = {
      ARGOCD_OPTS        = local.argocd_opts
      KUBECONFIG_CONTENT = var.kubeconfig
      ARGOCD_AUTH_TOKEN  = jwt_hashed_token.argocd.token
    }
  }
}

resource "random_password" "oauth2_cookie_secret" {
  length  = 16
  special = false
}
