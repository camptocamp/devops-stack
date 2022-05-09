locals {
  base_domain = coalesce(var.base_domain, format("%s.nip.io", replace(scaleway_lb_ip.this.ip_address, ".", "-")))

  kubeconfig = module.cluster.kubeconfig_file

  default_nodepools = {
    "router" = {
      node_type           = "DEV1-M"
      size                = 2
      min_size            = 2
      max_size            = 3
      autohealing         = true
      autoscaling         = false
      placement_group_id  = null
      container_runtime   = "containerd"
      tags                = []
      wait_for_pool_ready = true
      kubelet_args        = null
      zone                = null
      upgrade_policy = {
        max_surge       = 0
        max_unavailable = 1
      }
    },
  }
  nodepools = coalesce(var.nodepools, local.default_nodepools)
}

resource "scaleway_lb_ip" "this" {}

resource "scaleway_lb" "this" {
  zone       = var.zone
  ip_id      = scaleway_lb_ip.this.id
  type       = var.lb_type
  release_ip = false
}

module "cluster" {
  source  = "particuleio/kapsule/scaleway"
  version = "5.0.0"

  kubernetes_version = var.kubernetes_version
  cluster_name       = var.cluster_name
  region             = var.region

  cluster_type = var.cluster_type
  cni_plugin   = var.cluster_type == "kosmos" ? "kilo" : "cilium"

  admission_plugins = [
    "PodNodeSelector",
  ]

  node_pools = local.nodepools
}
