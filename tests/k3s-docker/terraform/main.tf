module "cluster" {
  source = "../../../modules/k3s/docker"

  cluster_name = "default"
  node_count   = 1

  repo_url        = var.repo_url
  target_revision = var.target_revision

  extra_app_projects = [
    {
      metadata = {
        name      = "demo-project"
        namespace = "argocd"
      }
      spec = {
        description = "Demo project"
        sourceRepos = ["*"]

        destinations = [
          {
            server    = "https://kubernetes.default.svc"
            namespace = "demo-app"
          }
        ]

        clusterResourceWhitelist = [
          {
            group = ""
            kind  = "Namespace"
          }
        ]
      }
    }
  ]

  extra_apps = [
    {
      metadata = {
        name = "demo-app"
      }
      spec = {
        project = "demo-project"

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
