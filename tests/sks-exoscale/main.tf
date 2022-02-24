module "cluster" {
  source = "../../modules/sks/exoscale"

  cluster_name = var.cluster_name
  zone         = var.zone

  kubernetes_version = "1.22.5"

  nodepools = {
    "router-${var.cluster_name}" = {
      size          = 2
      instance_type = "standard.large"
    }

    "compute-${var.cluster_name}" = {
      size          = 2
      instance_type = "standard.large"
    }
  }
}

provider "argocd" {
  server_addr = "127.0.0.1:8080"
  auth_token  = module.cluster.argocd_auth_token
  insecure = true
  plain_text = true
  port_forward = true
  port_forward_with_namespace = module.cluster.argocd_namespace

  kubernetes {
    host                   = module.cluster.kubernetes.host
    client_certificate     = module.cluster.kubernetes.client_certificate
    client_key             = module.cluster.kubernetes.client_key
    cluster_ca_certificate = module.cluster.kubernetes.cluster_ca_certificate
  }
}

module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//modules/sks"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git//modules"

  cluster_name   = var.cluster_name
  argocd         = {
    namespace = module.cluster.argocd_namespace
    domain    = module.cluster.argocd_domain
  }
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"

  depends_on = [ module.ingress ]
}

module "monitoring" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//modules"

  cluster_name     = var.cluster_name
  oidc             = module.oidc.oidc
  argocd_namespace = module.cluster.argocd_namespace
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"
  metrics_archives = {}

  depends_on = [ module.oidc ]
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//modules"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  #  minio = {
  #    access_key = module.storage.access_key
  #    secret_key = module.storage.secret_key
  #  }

  depends_on = [ module.monitoring ]
}


module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//modules/self-signed"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  depends_on = [ module.monitoring ]
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//modules"

  cluster_name   = var.cluster_name
  oidc           = module.oidc.oidc
  argocd         = {
    namespace = module.cluster.argocd_namespace
    server_secretkey = module.cluster.argocd_server_secretkey
    accounts_pipeline_tokens = module.cluster.argocd_accounts_pipeline_tokens
    server_admin_password = module.cluster.argocd_server_admin_password
    domain = module.cluster.argocd_domain
    admin_enabled = true
  }
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"

  depends_on = [ module.cert-manager, module.monitoring ]
}

module "my-apps" {
  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git//modules"

  argocd_namespace = module.cluster.argocd_namespace

  name = "my-apps"
  namespace = "my-apps"

  project_source_repos = [ "https://github.com/raphink/applicationsets-demo" ]

  generators = [
    {
      git = {
        repoURL     = "https://github.com/raphink/applicationsets-demo"
        revision    = "HEAD"
        directories = [
          { path = "*" }
        ]
      }
    }
  ]

  template = {
    metadata = {
      name = "{{path.basename}}"
    }
    spec = {
      project = "my-apps"
      source = {
        repoURL        = "https://github.com/raphink/applicationsets-demo"
        targetRevision = "HEAD"
        path           = "{{path}}"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "my-apps"
      }
      syncPolicy = {
        automated = {
          prune     = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [ module.argocd ]
}