locals {
  base_domain                       = coalesce(var.base_domain, format("%s.nip.io", replace(module.cluster.ingress_ip_address, ".", "-")))
  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubeconfig                        = module.cluster.kubeconfig
  minio = {
    access_key = var.enable_minio ? random_password.minio_accesskey.0.result : ""
    secret_key = var.enable_minio ? random_password.minio_secretkey.0.result : ""
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

provider "kubernetes-alpha" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

module "argocd" {
  source = "../../argocd-helm"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  extra_app_projects      = var.extra_app_projects
  extra_application_sets  = var.extra_application_sets
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  argocd_server_secretkey = var.argocd_server_secretkey

  cluster_issuer = "ca-issuer"
  oidc = var.oidc != null ? var.oidc : {
    issuer_url    = format("https://keycloak.apps.%s/auth/realms/kubernetes", local.base_domain)
    oauth_url     = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/auth", local.base_domain)
    token_url     = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/token", local.base_domain)
    api_url       = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/userinfo", local.base_domain)
    client_id     = "applications"
    client_secret = random_password.clientsecret.result
    oauth2_proxy_extra_args = [
      "--insecure-oidc-skip-issuer-verification=true",
      "--ssl-insecure-skip-verify=true",
    ]
  }
  minio = {
    enable     = var.enable_minio
    access_key = local.minio.access_key
    secret_key = local.minio.secret_key
  }
  keycloak = {
    enable         = var.oidc == null ? true : false
    admin_password = random_password.admin_password.result
  }
  loki = {
    bucket_name = "loki"
  }
  metrics_archives = {
    bucket_name = "thanos",
    bucket_config = {
      "type" = "S3",
      "config" = {
        "bucket"     = "thanos",
        "endpoint"   = "minio.minio.svc:9000",
        "insecure"   = true,
        "access_key" = local.minio.access_key,
        "secret_key" = local.minio.secret_key
      }
    }
  }
  grafana = {
    admin_password = local.grafana_admin_password
    generic_oauth_extra_args = {
      tls_skip_verify_insecure = true
    }
  }
  app_of_apps_values_overrides = [
    templatefile("${path.module}/../values.tmpl.yaml",
      {
        base_domain      = local.base_domain
        cluster_name     = var.cluster_name
        minio_access_key = local.minio.access_key
        minio_secret_key = local.minio.secret_key
        root_cert        = base64encode(tls_self_signed_cert.root.cert_pem)
        root_key         = base64encode(tls_private_key.root.private_key_pem)
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
