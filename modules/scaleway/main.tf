locals {
  base_domain = coalesce(var.base_domain, format("%s.nip.io", replace(scaleway_lb_ip.this.ip_address, ".", "-")))

  kubeconfig = module.cluster.kubeconfig_file

  kubernetes = {
    host                   = module.cluster.kubeconfig.0.host
    token                  = module.cluster.kubeconfig.0.token
    cluster_ca_certificate = base64decode(module.cluster.kubeconfig.0.cluster_ca_certificate)
  }

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

provider "helm" {
  kubernetes {
    host                   = local.kubernetes.host
    token                  = local.kubernetes.token
    cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes.host
  token                  = local.kubernetes.token
  cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
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

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  extra_app_projects      = var.extra_app_projects
  extra_application_sets  = var.extra_application_sets
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  argocd_server_secretkey = var.argocd_server_secretkey
  cluster_issuer          = "letsencrypt-prod"

  repositories = var.repositories

  depends_on = [
    module.cluster,
  ]
}

resource "tls_private_key" "root" {
  algorithm = "ECDSA"
}

resource "tls_self_signed_cert" "root" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.root.private_key_pem

  subject {
    common_name  = "devops-stack.camptocamp.com"
    organization = "Camptocamp, SA"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
  ]

  is_ca_certificate = true
}
