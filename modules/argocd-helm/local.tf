locals {
  oidc_defaults = {
    issuer_url              = ""
    oauth_url               = ""
    token_url               = ""
    api_url                 = ""
    client_id               = "CHANGEME"
    client_secret           = "CHANGEME"
    oauth2_proxy_extra_args = []
  }
  oidc = merge(
    local.oidc_defaults,
    var.oidc,
  )

  argocd_defaults = {
    domain = "argocd.apps.${var.cluster_name}.${var.base_domain}"
  }
  argocd = merge(
    local.argocd_defaults,
    var.argocd,
  )

  metrics_server_defaults = {
    enable = true
  }
  metrics_server = merge(
    local.metrics_server_defaults,
    var.metrics_server,
  )

  traefik_defaults = {
    enable = true
  }
  traefik = merge(
    local.traefik_defaults,
    var.traefik,
  )

  loki_defaults = {
    bucket_name = ""
    enable      = true
  }
  loki = merge(
    local.loki_defaults,
    var.loki,
  )

  minio_defaults = {
    enable     = false
    access_key = ""
    secret_key = ""
    domain     = "minio.apps.${var.cluster_name}.${var.base_domain}"
  }
  minio = merge(
    local.minio_defaults,
    var.minio,
  )
  metrics_archives_defaults = {
    bucket_name      = "thanos"
    query_domain     = "thanos-query.${var.cluster_name}.${var.base_domain}"
    bucketweb_domain = "thanos-bucketweb.${var.cluster_name}.${var.base_domain}"
  }
  metrics_archives = merge(
    local.metrics_archives_defaults,
    var.metrics_archives,
  )
  cert_manager_defaults = {
    enable = true
  }
  cert_manager = merge(
    local.cert_manager_defaults,
    var.cert_manager,
  )
  kube_prometheus_stack_defaults = {
    enable = true
  }
  kube_prometheus_stack = merge(
    local.kube_prometheus_stack_defaults,
    var.kube_prometheus_stack,
  )

  cluster_autoscaler_defaults = {
    enable = false
  }
  cluster_autoscaler = merge(
    local.cluster_autoscaler_defaults,
    var.cluster_autoscaler,
  )
}
