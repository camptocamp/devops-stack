locals {
  kubernetes_version       = "1.28.1"
  cluster_name             = "YOUR_CLUSTER_NAME"
  zone                     = "YOUR_CLUSTER_ZONE"
  service_level            = "starter"
  base_domain              = "your.domain.here"
  activate_wildcard_record = true
  cluster_issuer           = "letsencrypt-staging"
  enable_service_monitor   = false # Can be enabled after the first bootstrap.
  app_autosync             = true ? { allow_empty = false, prune = true, self_heal = true } : {}
}
