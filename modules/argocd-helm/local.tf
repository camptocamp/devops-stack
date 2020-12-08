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
    generic_oauth_extra_args = {}
    domain                   = "grafana.apps.${var.cluster_name}.${var.base_domain}"
  }
  grafana = merge(
    local.grafana_defaults,
    var.grafana,
  )

  prometheus_defaults = {
    domain = "prometheus.apps.${var.cluster_name}.${var.base_domain}"
  }
  prometheus = merge(
    local.prometheus_defaults,
    var.prometheus,
  )

  alertmanager_defaults = {
    domain = "alertmanager.apps.${var.cluster_name}.${var.base_domain}"
  }
  alertmanager = merge(
    local.alertmanager_defaults,
    var.alertmanager,
  )

  loki_defaults = {
    bucket_name = ""
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

  olm_defaults = {
    enable = false
  }
  olm = merge(
    local.olm_defaults,
    var.olm,
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
}
