module "helloworld_apps" {
  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git?ref=v2.1.0"
  # source = "../../devops-stack-module-applicationset"

  dependency_ids = {
    argocd = module.argocd.id
  }

  name                   = "helloworld-apps"
  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  project_dest_namespace = "*"
  project_source_repo    = "https://github.com/camptocamp/devops-stack-helloworld-templates.git"

  app_autosync = local.app_autosync

  generators = [
    {
      git = {
        repoURL  = "https://github.com/camptocamp/devops-stack-helloworld-templates.git"
        revision = "main"

        directories = [
          {
            path = "apps/*"
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
      project = "helloworld-apps"

      source = {
        repoURL        = "https://github.com/camptocamp/devops-stack-helloworld-templates.git"
        targetRevision = "main"
        path           = "{{path}}"

        helm = {
          valueFiles = []
          # The following value defines this global variables that will be available to all apps in apps/*
          # These are needed to generate the ingresses containing the name and base domain of the cluster.
          values = <<-EOT
            cluster:
              name: "${local.cluster_name}"
              domain: "${local.base_domain}"
              issuer: "${local.cluster_issuer}"
            apps:
              keycloak: true
              traefik: false
              minio: true
              grafana: true
              prometheus: true
              thanos: true
          EOT
        }
      }

      destination = {
        name      = "in-cluster"
        namespace = "{{path.basename}}"
      }

      syncPolicy = {
        automated = {
          allowEmpty = false
          selfHeal   = true
          prune      = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}
