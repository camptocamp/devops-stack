locals {
  docker_gateway                    = compact(data.docker_network.kind.ipam_config[*].gateway)[0]
  base_domain                       = coalesce(var.base_domain, format("%s.nip.io", replace(local.docker_gateway, ".", "-")))
  kubernetes_host                   = kind_cluster.cluster.endpoint
  kubernetes_client_certificate     = kind_cluster.cluster.client_certificate
  kubernetes_client_key             = kind_cluster.cluster.client_key
  kubernetes_cluster_ca_certificate = kind_cluster.cluster.cluster_ca_certificate
  kubeconfig                        = kind_cluster.cluster.kubeconfig

  minio = {
    access_key = var.enable_minio ? random_password.minio_accesskey.0.result : ""
    secret_key = var.enable_minio ? random_password.minio_secretkey.0.result : ""
  }
}

data "docker_network" "kind" {
  name       = "kind"
  depends_on = [kind_cluster.cluster]
}

resource "kind_cluster" "cluster" {
  name = var.cluster_name

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }
  }
}

provider "helm" {
  kubernetes {
    host               = local.kubernetes_host
    client_certificate = local.kubernetes_client_certificate
    client_key         = local.kubernetes_client_key
    insecure           = true
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
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
  cluster_issuer          = "ca-issuer"

  repositories = var.repositories
}

data "kubernetes_secret" "keycloak_admin_password" {
  metadata {
    name      = "credential-keycloak"
    namespace = "keycloak"
  }

  depends_on = [module.argocd]
}

resource "random_password" "clientsecret" {
  length  = 16
  special = false
}

resource "random_password" "jdoe_password" {
  length  = 16
  special = false
}

resource "random_password" "minio_accesskey" {
  count   = var.enable_minio ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "minio_secretkey" {
  count   = var.enable_minio ? 1 : 0
  length  = 16
  special = false
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
