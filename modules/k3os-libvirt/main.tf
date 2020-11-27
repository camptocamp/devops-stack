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
  source  = "camptocamp/k3os/libvirt"
  version = "0.3.0"

  cluster_name = var.cluster_name
  k3os_version = var.k3os_version
  node_count   = var.node_count

  server_memory = var.server_memory
  agent_memory  = var.agent_memory
}

module "argocd" {
  source = "../argocd-helm"

  depends_on = [
    module.cluster,
  ]
}

resource "helm_release" "app_of_apps" {
  name              = "app-of-apps"
  chart             = "${path.module}/../../argocd/app-of-apps"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    templatefile("${path.module}/../../argocd/app-of-apps/values.tmpl.yaml",
      {
        repo_url                        = var.repo_url
        target_revision                 = var.target_revision
        argocd_accounts_pipeline_tokens = module.argocd.argocd_accounts_pipeline_tokens
        extra_apps                      = var.extra_apps
        cluster_name                    = var.cluster_name
        base_domain                     = local.base_domain
        cluster_issuer                  = "ca-issuer"
        oidc_issuer_url                 = format("https://keycloak.apps.%s/auth/realms/kubernetes", local.base_domain)
        oauth2_oauth_url                = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/auth", local.base_domain)
        oauth2_token_url                = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/token", local.base_domain)
        oauth2_api_url                  = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/userinfo", local.base_domain)
        client_id                       = "applications"
        client_secret                   = random_password.clientsecret.result
        cookie_secret                   = random_password.oauth2_cookie_secret.result
        admin_password                  = random_password.admin_password.result
        minio_access_key                = var.enable_minio ? random_password.minio_accesskey.0.result : ""
        minio_secret_key                = var.enable_minio ? random_password.minio_secretkey.0.result : ""
        enable_efs                      = false
        enable_keycloak                 = true
        enable_olm                      = true
        enable_minio                    = var.enable_minio

        oauth2_proxy_extra_args = [
          "--insecure-oidc-skip-issuer-verification=true",
          "--ssl-insecure-skip-verify=true",
        ]

        grafana_generic_oauth_extra_args = {
          tls_skip_verify_insecure = true
        }
      }
    ),
    templatefile("${path.module}/values.tmpl.yaml",
      {
        root_cert = base64encode(tls_self_signed_cert.root.cert_pem)
        root_key  = base64encode(tls_private_key.root.private_key_pem)
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.argocd,
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

resource "random_password" "oauth2_cookie_secret" {
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
