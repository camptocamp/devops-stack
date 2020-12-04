module "cluster" {
  source = "../../../modules/k3s-docker"

  cluster_name = terraform.workspace
  node_count   = 1

  repo_url        = var.repo_url
  target_revision = var.target_revision

  network_name = "bridge"

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
