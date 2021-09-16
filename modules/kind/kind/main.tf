locals {
  base_domain                       = "127-0-0-1.nip.io"
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
  cluster_issuer          = "ca-issuer"
  wait_for_app_of_apps    = var.wait_for_app_of_apps

  oidc = var.oidc != null ? var.oidc : {
    issuer_url    = format("https://keycloak.apps.%s.%s/auth/realms/kubernetes", var.cluster_name, local.base_domain)
    oauth_url     = format("https://keycloak.apps.%s.%s/auth/realms/kubernetes/protocol/openid-connect/auth", var.cluster_name, local.base_domain)
    token_url     = format("https://keycloak.apps.%s.%s/auth/realms/kubernetes/protocol/openid-connect/token", var.cluster_name, local.base_domain)
    api_url       = format("https://keycloak.apps.%s.%s/auth/realms/kubernetes/protocol/openid-connect/userinfo", var.cluster_name, local.base_domain)
    client_id     = "devops-stack-applications"
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
    enable        = var.oidc == null ? true : false
    jdoe_password = random_password.jdoe_password.result
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

  repositories = var.repositories

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        root_cert = base64encode(tls_self_signed_cert.root.cert_pem)
        root_key  = base64encode(tls_private_key.root.private_key_pem)
      }
    ),
    var.app_of_apps_values_overrides,
  ]
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
