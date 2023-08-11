locals {
  kubernetes_version     = "v1.27.3"
  cluster_name           = "YOUR_CLUSTER_NAME"
  base_domain            = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  cluster_issuer         = "ca-issuer"
  enable_service_monitor = false # Can be enabled after the first bootstrap.
  app_autosync           = true ? { allow_empty = false, prune = true, self_heal = true } : {}
}
