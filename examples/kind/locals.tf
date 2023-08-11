locals {
  kubernetes_version     = "v1.27.1"
  cluster_name           = "kind-cluster"
  base_domain            = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  cluster_issuer         = "ca-issuer"
  enable_service_monitor = false

  devops_stack_secrets = {
    loki = {
      loki-secret-key = random_password.loki_secretkey.result
    }
    thanos = {
      loki-secret-key = random_password.thanos_secretkey.result
    }
  }
}
