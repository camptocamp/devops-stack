locals {
  repo_url        = "https://github.com/camptocamp/camptocamp-devops-stack.git"
  target_revision = "HEAD"

  base_domain                       = module.cluster.base_domain
  kubernetes_host                   = module.cluster.kubernetes_host
  kubernetes_username               = module.cluster.kubernetes_username
  kubernetes_password               = module.cluster.kubernetes_password
  kubernetes_cluster_ca_certificate = module.cluster.kubernetes_cluster_ca_certificate
}

module "cluster" {
  source = "git::https://github.com/camptocamp/camptocamp-devops-stack.git//modules/k3os-libvirt?ref=HEAD"

  cluster_name = terraform.workspace
  node_count   = 1

  repo_url        = local.repo_url
  target_revision = local.target_revision
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
    repoURL: ${local.repo_url}
    targetRevision: ${local.target_revision}

baseDomain: ${local.base_domain}
          EOT
  ]

  depends_on = [
    module.cluster,
  ]
}
