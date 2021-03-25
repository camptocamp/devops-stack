locals {
  oidc_defaults = {
    issuer_url              = ""
    oauth_url               = ""
    token_url               = ""
    api_url                 = ""
    client_id               = ""
    client_secret           = ""
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

  grafana_defaults = {
    enable                   = true
    generic_oauth_extra_args = {}
    domain                   = "grafana.apps.${var.cluster_name}.${var.base_domain}"
  }
  grafana = merge(
    local.grafana_defaults,
    var.grafana,
  )
  metrics_server_defaults = {
    enable = true
  }
  metrics_server = merge(
    local.metrics_server_defaults,
    var.metrics_server,
  )
  prometheus_defaults = {
    domain = "prometheus.apps.${var.cluster_name}.${var.base_domain}"
    enable = true
  }
  prometheus = merge(
    local.prometheus_defaults,
    var.prometheus,
  )

  alertmanager_defaults = {
    enable = true
    domain = "alertmanager.apps.${var.cluster_name}.${var.base_domain}"
  }
  alertmanager = merge(
    local.alertmanager_defaults,
    var.alertmanager,
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
    enable = true
  }
  loki = merge(
    local.loki_defaults,
    var.loki,
  )

  efs_provisioner_defaults = {
    enable = false
  }
  efs_provisioner = merge(
    local.efs_provisioner_defaults,
    var.efs_provisioner,
  )

  keycloak_defaults = {
    enable         = false
    admin_password = ""
    domain         = "keycloak.apps.${var.cluster_name}.${var.base_domain}"
  }
  keycloak = merge(
    local.keycloak_defaults,
    var.keycloak,
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
}
