locals {
  base_domain                       = var.base_domain
  all_domains                       = toset(compact(distinct(concat([var.base_domain], var.other_domains))))
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)

  context                           = yamldecode(module.cluster.kubeconfig)
  kubeconfig                        = module.cluster.kubeconfig

  ovh_s3_access_key_id     = ovh_cloud_project_user_s3_credential.s3_op_creds.access_key_id
  ovh_s3_secret_access_key = ovh_cloud_project_user_s3_credential.s3_op_creds.secret_access_key

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

module "cluster" {
  source  = "qalita-io/publiccloud-kube/ovh"
  version = "0.1.0"

  kubernetes_version = var.kubernetes_version
  private_network_id = ovh_cloud_project_network_private.net
  cluster_name    = var.cluster_name
  cluster_region  = var.cluster_region
  flavor_name     = var.flavor_name
  desired_nodes   = var.desired_nodes
  max_nodes       = var.max_nodes
  min_nodes       = var.min_nodes
}

module "argocd" {
  source = "../argocd-helm"

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
  wait_for_app_of_apps    = var.wait_for_app_of_apps

  oidc = merge(local.oidc, var.prometheus_oauth2_proxy_args)

  keycloak = {
    enable   = var.oidc == null ? true : false
    user_map = local.keycloak_user_map
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
        "endpoint"   = join(".",["https://s3",var.cluster_region,"io.cloud.ovh.net"]),
        "insecure"   = true,
        "access_key" = local.ovh_s3_access_key_id,
        "secret_key" = local.ovh_s3_secret_access_key
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
        base_domain      = local.base_domain
        cluster_name     = var.cluster_name
        ovh_s3_access_key = local.ovh_s3_access_key_id
        ovh_s3_secret_key = local.ovh_s3_secret_access_key
        cert_manager_dns01 = var.cert_manager_dns01
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

resource "ovh_cloud_project_user" "s3_op" {
  description  = "user allowed to manage the project's OVH object_store"
  role_names   = [
    "objectstore_operator"
  ]
}

resource "ovh_cloud_project_user" "net_op" {
  description  = "user allowed to manage the project's OVH network"
  role_names   = [
    "network_operator"
  ]
}

resource "ovh_cloud_project_user_s3_credential" "s3_op_creds" {
  user_id      = ovh_cloud_project_user.s3_op.id
}

resource "ovh_cloud_project_network_private" "net" {
  name       = format("%s-net",local.cluster_name)
}

data "ovh_order_cart" "mycart" {
  ovh_subsidiary = "fr"
}

data "ovh_order_cart_product_plan" "zone" {
  cart_id        = data.ovh_order_cart.mycart.id
  price_capacity = "renew"
  product        = "dns"
  plan_code      = "zone"
}

resource "ovh_domain_zone" "zone" {
  ovh_subsidiary = data.ovh_order_cart.mycart.ovh_subsidiary
  payment_mean   = "fidelity"

  plan {
    duration     = data.ovh_order_cart_product_plan.zone.selected_price.0.duration
    plan_code    = data.ovh_order_cart_product_plan.zone.plan_code
    pricing_mode = data.ovh_order_cart_product_plan.zone.selected_price.0.pricing_mode

    configuration {
      label = "zone"
      value = format("%s.%s",var.cluster_name,var.base_domain)
    }

    configuration {
      label = "template"
      value = "minimized"
    }
  }
}
