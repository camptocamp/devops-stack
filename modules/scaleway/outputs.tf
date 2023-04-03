output "base_domain" {
  value = local.base_domain
}

output "lb_ip_address" {
  value = scaleway_lb_ip.this.ip_address
}

output "lb_id" {
  value = scaleway_lb.this.id
}

output "kube_admin_config" {
  value = {
    host                   = module.cluster.kubeconfig.0.host
    token                  = module.cluster.kubeconfig.0.token
    cluster_ca_certificate = base64decode(module.cluster.kubeconfig.0.cluster_ca_certificate)
  }
}

output "kubeconfig_file" {
  value     = local.kubeconfig
  sensitive = true
}

output "node_pools" {
  value = module.cluster.node_pools
}

output "cluster_id" {
  value = module.cluster.id
}
