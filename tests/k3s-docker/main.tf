module "cluster" {
  source = "../../modules/k3s/docker"

  cluster_name = var.cluster_name

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

  extra_application_sets = [
    {
      metadata = {
        name      = "demo-apps"
        namespace = "argocd"

        annotations = {
          "argocd.argoproj.io/sync-options" = "SkipDryRunOnMissingResource=true"
        }
      }

      spec = {
        generators = [
          {
            git = {
              repoURL  = var.repo_url
              revision = var.target_revision

              directories = [
                {
                  path = "tests/argocd/*"
                }
              ]
            }
          }
        ]

        template = {
          metadata = {
            name = "{{path.basename}}"
          }

          spec = {
            project = "demo-project"

            source = {
              repoURL        = var.repo_url
              targetRevision = var.target_revision
              path           = "{{path}}"
            }

            destination = {
              server    = "https://kubernetes.default.svc"
              namespace = "demo-app"
            }

            syncPolicy = {
              automated = {
                selfHeal = true
              }

              syncOptions = [
                "CreateNamespace=true"
              ]
            }
          }
        }
      }
    }
  ]
}
