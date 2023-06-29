output "base_domain" {
  value = local.base_domain
}

locals {
  kubeconfig = yamldecode(module.cluster.kubeconfig)
}
