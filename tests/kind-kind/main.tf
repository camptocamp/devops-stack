module "cluster" {
  source = "../../modules/kind/kind"

  cluster_name = var.cluster_name

  repo_url        = var.repo_url
  target_revision = var.target_revision
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
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//nodeport"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain
  extra_yaml       = [yamlencode({ 
    traefik = {
      deployment = {
        replicas = 1
      }
    }
  })]
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git"

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
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git"

  cluster_name     = var.cluster_name
  oidc             = module.oidc.oidc
  argocd_namespace = module.cluster.argocd_namespace
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"
  metrics_archives = {}

  depends_on = [ module.oidc ]
}


module "storage" {
  source = "git::https://github.com/camptocamp/devops-stack-module-minio.git"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain
  cluster_issuer   = "ca-issuer"

  minio = {
    buckets = {
      loki = {}
      thanos = {}
    }
  }

  depends_on = [ module.monitoring ]
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//k3s"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  minio = {
    access_key = module.storage.access_key
    secret_key = module.storage.secret_key
  }

  depends_on = [ module.monitoring, module.storage ]
}


module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  depends_on = [ module.monitoring ]
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git"

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
  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git"

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