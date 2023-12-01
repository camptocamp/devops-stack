locals {
  kubernetes_version       = "1.28.3"
  cluster_name             = "YOUR_CLUSTER_NAME"
  zone                     = "YOUR_CLUSTER_ZONE"
  service_level            = "starter"
  base_domain              = "your.domain.here"
  activate_wildcard_record = true
  cluster_issuer           = module.cert-manager.cluster_issuers.staging
  letsencrypt_issuer_email = "YOUR_EMAIL_ADDRESS"
  enable_service_monitor   = false # Can be enabled after the first bootstrap.
  app_autosync             = true ? { allow_empty = false, prune = true, self_heal = true } : {}
}
