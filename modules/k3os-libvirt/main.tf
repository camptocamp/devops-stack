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

module "cluster" {
  source  = "camptocamp/k3os/libvirt"
  version = "0.2.4"

  cluster_name = var.cluster_name
  k3os_version = var.k3os_version
  node_count   = var.node_count

  server_memory = 2048
  agent_memory  = 2048
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
    templatefile("${path.module}/values.tmpl.yaml",
      {
        cluster_name     = var.cluster_name,
        base_domain      = local.base_domain,
        repo_url         = var.repo_url,
        target_revision  = var.target_revision,
        clientid         = "applications"
        clientsecret     = random_password.clientsecret.result
        admin_password   = random_password.admin_password.result
        cookie_secret    = random_password.cookie_secret.result
        enable_minio     = var.enable_minio
        minio_access_key = var.enable_minio ? random_password.minio_accesskey.0.result : ""
        minio_secret_key = var.enable_minio ? random_password.minio_secretkey.0.result : ""
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    helm_release.argocd,
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

resource "random_password" "cookie_secret" {
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
