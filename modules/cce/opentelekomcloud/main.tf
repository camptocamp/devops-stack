locals {
  base_domain                       = var.base_domain
  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubeconfig                        = module.cluster.kubeconfig
  keycloak_user_map                 = { for username, infos in var.keycloak_users : username => merge(infos, tomap({ password = random_password.keycloak_passwords[username].result })) }
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

module "cluster" {
  source  = "camptocamp/cce/opentelekomcloud"
  version = "0.3.0"

  flavor_id    = var.flavor_id
  vpc_id       = var.vpc_id
  cluster_name = var.cluster_name
  subnet_id    = var.network_id # somehow the subnet_id in CCE cluster resource is the network_id
  node_pools   = var.node_pools
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  argocd_server_secretkey = var.argocd_server_secretkey
  cluster_issuer          = "ca-issuer"

  depends_on = [
    module.cluster,
  ]
}

resource "random_password" "clientsecret" {
  length  = 16
  special = false
}

resource "random_password" "keycloak_passwords" {
  for_each = var.keycloak_users
  length   = 16
  special  = false
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

resource "opentelekomcloud_lb_loadbalancer_v2" "ingress" {
  name          = format("%s.%s", var.cluster_name, var.base_domain)
  vip_subnet_id = var.subnet_id
}
