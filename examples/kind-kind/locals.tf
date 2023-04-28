locals {
  kubernetes_version = "v1.27.1"
  cluster_name       = "kind-cluster"
  base_domain        = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  cluster_issuer     = "ca-issuer"
}
