locals {
  base_domain                       = format("%s.nip.io", replace(module.cluster.ingress_ip_address, ".", "-"))
  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_username               = local.context.users.0.user.username
  kubernetes_password               = local.context.users.0.user.password
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
}

provider "helm" {
  kubernetes {
    insecure         = true
    host             = local.kubernetes_host
    username         = local.kubernetes_username
    password         = local.kubernetes_password
    load_config_file = false
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  username               = local.kubernetes_username
  password               = local.kubernetes_password
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  load_config_file       = false
}

module "cluster" {
  source  = "camptocamp/k3s/docker"
  version = "0.6.0"

  network_name = "bridge"
  cluster_name = var.cluster_name
  k3s_version  = var.k3s_version
  node_count   = var.node_count
  server_config = [
    "--disable", "traefik",
    "--disable", "metrics-server",
  ]
}

module "argocd" {
  source = "../argocd-helm"

  repo_url        = var.repo_url
  target_revision = var.target_revision
  extra_apps      = var.extra_apps
  cluster_name    = var.cluster_name
  base_domain     = local.base_domain
  cluster_issuer  = "ca-issuer"
  oidc = {
    issuer_url              = format("https://keycloak.apps.%s/auth/realms/kubernetes", local.base_domain)
    oauth_url               = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/auth", local.base_domain)
    token_url               = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/token", local.base_domain)
    api_url                 = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/userinfo", local.base_domain)
    client_id               = "applications"
    client_secret           = random_password.clientsecret.result
    oauth2_proxy_extra_args = [
      "--insecure-oidc-skip-issuer-verification=true",
      "--ssl-insecure-skip-verify=true",
    ]
  }
  minio                           = {
    enable     = var.enable_minio
    access_key = var.enable_minio ? random_password.minio_accesskey.0.result : ""
    secret_key = var.enable_minio ? random_password.minio_secretkey.0.result : ""
  }
  keycloak                        = {
    enable         = true
    admin_password = random_password.admin_password.result
  }
  loki                            = {
    bucket_name = "loki"
  }
  olm                             = {
    enable = true
  }

  grafana = {
    generic_oauth_extra_args = {
      tls_skip_verify_insecure = true
    }
  }

  app_of_apps_values_overrides    = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        root_cert = base64encode(tls_self_signed_cert.root.cert_pem)
        root_key  = base64encode(tls_private_key.root.private_key_pem)
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
  ]
}


resource "random_password" "clientsecret" {
  length  = 16
  special = false
}

resource "random_password" "admin_password" {
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
