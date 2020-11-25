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

  extra_apps = [
    {
      metadata = {
        name = "demo-app"
      }
      spec = {
        project = "default"

        source = {
          path           = "tests/k3os-docker/argocd/demo-app"
          repoURL        = var.repo_url
          targetRevision = var.target_revision

          helm = {
            values = <<EOT
spec:
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}

baseDomain: ${local.base_domain}
          EOT
          }
        }

        destination = {
          namespace = "demo-app"
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
