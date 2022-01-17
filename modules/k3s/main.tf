locals {
  base_domain                       = coalesce(var.base_domain, format("%s.nip.io", replace(module.cluster.ingress_ip_address, ".", "-")))
  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubeconfig                        = module.cluster.kubeconfig
  keycloak_user_map = { for username, infos in var.keycloak_users : username => merge(infos, tomap({ password = random_password.keycloak_passwords[username].result })) }
  oidc = var.oidc != null ? var.oidc : {
    issuer_url    = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack", var.cluster_name, local.base_domain)
    oauth_url     = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack/protocol/openid-connect/auth", var.cluster_name, local.base_domain)
    token_url     = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack/protocol/openid-connect/token", var.cluster_name, local.base_domain)
    api_url       = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack/protocol/openid-connect/userinfo", var.cluster_name, local.base_domain)
    client_id     = "devops-stack-applications"
    client_secret = random_password.clientsecret.result
    oauth2_proxy_extra_args = [
      "--insecure-oidc-skip-issuer-verification=true",
      "--ssl-insecure-skip-verify=true",
    ]
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

  oidc = local.oidc

  keycloak = {
    enable   = var.oidc == null ? true : false
    user_map = local.keycloak_user_map
  }

  loki = {
    bucket_name = "loki"
  }

  #metrics_archives = {
  #  bucket_name = "thanos",
  #  bucket_config = {
  #    "type" = "S3",
  #    "config" = {
  #      "bucket"     = "thanos",
  #      "endpoint"   = "minio.minio.svc:9000",
  #      "insecure"   = true,
  #      "access_key" = local.minio.access_key,
  #      "secret_key" = local.minio.secret_key
  #    }
  #  }
  #}

  repositories = var.repositories

  app_of_apps_values_overrides = [
    templatefile("${path.module}/../values.tmpl.yaml",
      {
        base_domain      = local.base_domain
        cluster_name     = var.cluster_name
        #root_cert        = base64encode(tls_self_signed_cert.root.cert_pem)
        #root_key         = base64encode(tls_private_key.root.private_key_pem)
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
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

resource "random_password" "keycloak_passwords" {
  for_each = var.keycloak_users
  length   = 16
  special  = false
}
