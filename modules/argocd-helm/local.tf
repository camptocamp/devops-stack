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
    domain    = "argocd.apps.${var.cluster_name}.${var.base_domain}"
    node_pool = ""
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
    enable    = true
    node_pool = ""
  }
  traefik = merge(
    local.traefik_defaults,
    var.traefik,
  )

  loki_defaults = {
    bucket_name = ""
    enable      = true
    node_pool   = ""
  }
  loki = merge(
    local.loki_defaults,
    var.loki,
  )

  keycloak_defaults = {
    enable   = false
    user_map = {}
    domain   = "keycloak.apps.${var.cluster_name}.${var.base_domain}"
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
    enable    = true
    node_pool = ""
  }
  cert_manager = merge(
    local.cert_manager_defaults,
    var.cert_manager,
  )
  kube_prometheus_stack_defaults = {
    enable    = true
    node_pool = ""
  }
  kube_prometheus_stack = merge(
    local.kube_prometheus_stack_defaults,
    var.kube_prometheus_stack,
  )
  csi_secrets_store_provider_azure_defaults = {
    node_pool = ""
  }
  csi_secrets_store_provider_azure = merge(
    local.csi_secrets_store_provider_azure_defaults,
    var.csi_secrets_store_provider_azure,
  )
  secrets_store_csi_driver_defaults = {
    node_pool = ""
  }
  secrets_store_csi_driver = merge(
    local.secrets_store_csi_driver_defaults,
    var.secrets_store_csi_driver,
  )
  aad_pod_identity_defaults = {
    node_pool = ""
  }
  aad_pod_identity = merge(
    local.aad_pod_identity_defaults,
    var.aad_pod_identity,
  )
  cluster_autoscaler_defaults = {
    enable = false
  }
  cluster_autoscaler = merge(
    local.cluster_autoscaler_defaults,
    var.cluster_autoscaler,
  )
}
