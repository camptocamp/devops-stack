module "helloworld_apps" {
  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git?ref=v3.0.0"

  dependency_ids = {
    argocd = module.argocd.id
  }

  name                   = "helloworld-apps"
  project_dest_namespace = "*"
  project_source_repo    = "https://github.com/camptocamp/devops-stack-helloworld-templates.git"

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
              name: "${module.sks.cluster_name}"
              domain: "${module.sks.base_domain}"
              subdomain: "${local.subdomain}"
              issuer: "${local.cluster_issuer}"
            apps:
              longhorn: true
              grafana: true
              prometheus: true
              thanos: true
              alertmanager: true
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
