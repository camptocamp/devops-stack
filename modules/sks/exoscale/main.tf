locals {
  base_domain = coalesce(var.base_domain, format("%s.nip.io", replace(exoscale_nlb.this.ip_address, ".", "-")))

  kubeconfig = module.cluster.kubeconfig
  context    = yamldecode(module.cluster.kubeconfig)

  kubernetes = {
    host                   = local.context.clusters.0.cluster.server
    client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
    client_key             = base64decode(local.context.users.0.user.client-key-data)
    cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  }

  default_nodepools = {
    "router-${var.cluster_name}" = {
      size          = 2
      instance_type = "standard.large"
    },
  }

  router_nodepool = coalesce(var.router_nodepool, "router-${var.cluster_name}")
  nodepools       = coalesce(var.nodepools, local.default_nodepools)
  cluster_issuer  = (length(local.nodepools) > 1) ? "letsencrypt-prod" : "ca-issuer"
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes.host
    client_certificate     = local.kubernetes.client_certificate
    client_key             = local.kubernetes.client_key
    cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes.host
  client_certificate     = local.kubernetes.client_certificate
  client_key             = local.kubernetes.client_key
  cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
}

module "cluster" {
  source  = "camptocamp/sks/exoscale"
  version = "0.3.0"

  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  zone               = var.zone

  nodepools = local.nodepools
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//modules/bootstrap"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  extra_app_projects      = var.extra_app_projects
  extra_application_sets  = var.extra_application_sets
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  argocd_server_secretkey = var.argocd_server_secretkey
  cluster_issuer          = local.cluster_issuer

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
