output "base_domain" {
  value = local.base_domain
}

output "kubernetes" {
  value = {
    host                   = local.kubernetes_host
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}
