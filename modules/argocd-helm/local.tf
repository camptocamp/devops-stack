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

  grafana_defaults = {
    generic_oauth_extra_args = {}
  }
  grafana = merge(
    local.grafana_defaults,
    var.grafana,
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
  }
  minio = merge(
    local.minio_defaults,
    var.minio,
  )
}
