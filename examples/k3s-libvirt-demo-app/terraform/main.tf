locals {
  repo_url        = "https://github.com/camptocamp/camptocamp-devops-stack.git"
  target_revision = "v0.21.0"

  base_domain                       = module.cluster.base_domain
  kubernetes_host                   = module.cluster.kubernetes_host
  kubernetes_username               = module.cluster.kubernetes_username
  kubernetes_password               = module.cluster.kubernetes_password
  kubernetes_cluster_ca_certificate = module.cluster.kubernetes_cluster_ca_certificate
}

module "cluster" {
  source = "git::https://github.com/camptocamp/camptocamp-devops-stack.git//modules/k3s/libvirt?ref=v0.21.0"

  cluster_name = terraform.workspace
  node_count   = 1

  repo_url        = local.repo_url
  target_revision = local.target_revision

  extra_apps = [
    {
      metadata = {
        name = "project-apps"
      }
      spec = {
        project = "default"

        source = {
          path           = "argocd/project-apps"
          repoURL        = "https://github.com/example/myapp.gi"
          targetRevision = "HEAD"

          helm = {
            values = <<EOT
spec:
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}
          EOT
          }
        }

        destination = {
          namespace = "default"
          server    = "https://kubernetes.default.svc"
        }

        syncPolicy = {
          automated = {
            selfHeal = true
          }
        }
      }
    }
  ]
}
