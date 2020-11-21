locals {
  base_domain                       = module.cluster.base_domain
  kubernetes_host                   = module.cluster.kubernetes_host
  kubernetes_username               = module.cluster.kubernetes_username
  kubernetes_password               = module.cluster.kubernetes_password
  kubernetes_cluster_ca_certificate = module.cluster.kubernetes_cluster_ca_certificate
}

module "cluster" {
  source = "../../../modules/k3os-libvirt"

  cluster_name = terraform.workspace
  node_count   = 0

  repo_url        = var.repo_url
  target_revision = var.target_revision
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

resource "helm_release" "project_apps" {
  name              = "project-apps"
  chart             = "${path.module}/../argocd/project-apps"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    <<EOT
---
spec:
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}

baseDomain: ${local.base_domain}
          EOT
  ]

  depends_on = [
    module.cluster,
  ]
}
