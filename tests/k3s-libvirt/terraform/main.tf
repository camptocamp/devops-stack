module "cluster" {
  source = "../../../modules/k3s/libvirt"

  cluster_name = "default"
  node_count   = 0

  repo_url        = var.repo_url
  target_revision = var.target_revision
  server_memory   = 8192
  extra_apps = [
    {
      metadata = {
        name = "demo-app"
      }
      spec = {
        project = "default"

        source = {
          path           = "tests/k3s-docker/argocd/demo-app"
          repoURL        = var.repo_url
          targetRevision = var.target_revision

          helm = {
            values = <<EOT
spec:
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}

baseDomain: ${module.cluster.base_domain}
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
