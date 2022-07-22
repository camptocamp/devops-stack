locals {
  # Attention: argo CD oidc authentication on Keycloak doesn't work with non valid certificates.
  cluster_issuer = "letsencrypt-staging"
}

module "sks" {
  source = "../../modules/sks/exoscale"

  cluster_name = "ckg-test"
  base_domain  = "rd-infrastructure-exo.camptocamp.com"
  zone         = var.zone

  kubernetes_version = "1.23.8"

  nodepools = {
    "router-${module.sks.cluster_name}" = {
      size          = 2
      instance_type = "standard.small"
      labels        = {
        role = "router"
      }
      taints        = {
        router = "router:NoSchedule"
      }
    }

    "compute-${module.sks.cluster_name}" = {
      size          = 2
      instance_type = "standard.large"
      labels        = {}
      taints        = {}
    }
  }

  router_nodepool = "router-${module.sks.cluster_name}"
}

provider "kubernetes" {
  host                   = module.sks.kubernetes_host
  client_key             = module.sks.kubernetes_client_key
  client_certificate     = module.sks.kubernetes_client_certificate
  cluster_ca_certificate = module.sks.kubernetes_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.sks.kubernetes_host
    client_key             = module.sks.kubernetes_client_key
    client_certificate     = module.sks.kubernetes_client_certificate
    cluster_ca_certificate = module.sks.kubernetes_cluster_ca_certificate
  }
}

locals {
  argocd_namespace = "argocd"
}

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap"

  cluster_name     = module.sks.cluster_name
  base_domain      = module.sks.base_domain
  cluster_issuer   = local.cluster_issuer

  depends_on = [module.sks]
}

provider "argocd" {
  server_addr = "127.0.0.1:8080"
  auth_token = module.argocd_bootstrap.argocd_auth_token
  insecure = true
  plain_text = true
  port_forward = true
  port_forward_with_namespace = local.argocd_namespace

  kubernetes {
    host                   = module.sks.kubernetes_host
    client_key             = module.sks.kubernetes_client_key
    client_certificate     = module.sks.kubernetes_client_certificate
    cluster_ca_certificate = module.sks.kubernetes_cluster_ca_certificate
  }
}

module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//sks"

  cluster_name     = module.sks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.sks.base_domain

  helm_values = [{
    traefik = {
      nodeSelector = {
        "role" = "router"
      }
      tolerations = [{
        key      = "router"
        operator = "Equal"
        value    = "router"
        effect   = "NoSchedule"
      }]
    }
  }]

  depends_on = [module.argocd_bootstrap]
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git/"

  cluster_name   = module.sks.cluster_name
  argocd         = {
    namespace = local.argocd_namespace
    domain    = module.argocd_bootstrap.argocd_domain
  }
  base_domain    = module.sks.base_domain
  cluster_issuer = local.cluster_issuer

  depends_on = [ module.sks, module.argocd_bootstrap ]
}

module "monitoring" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git/"

  cluster_name     = module.sks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.sks.base_domain
  cluster_issuer   = local.cluster_issuer
  metrics_archives = {}

  prometheus = {
    oidc = module.oidc.oidc
  }
  alertmanager = {
    oidc = module.oidc.oidc
  }
  grafana = {
    oidc = module.oidc.oidc
  }

  depends_on = [ module.argocd_bootstrap ]
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git/"

  cluster_name     = module.sks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.sks.base_domain

  #  minio = {
  #    access_key = module.storage.access_key
  #    secret_key = module.storage.secret_key
  #  }

  depends_on = [ module.monitoring ]
}


module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//sks"

  cluster_name     = module.sks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.sks.base_domain
  router_pool_id   = module.sks.router_pool_id

  depends_on = [ module.monitoring ]
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git/"

  cluster_name     = module.sks.cluster_name
  oidc             = {
    name         = "OIDC"
    issuer       = module.oidc.oidc.issuer_url
    clientID     = module.oidc.oidc.client_id
    clientSecret = module.oidc.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
    requestedScopes = [
      "openid", "profile", "email"
    ]
  }
  argocd           = {
    namespace                = local.argocd_namespace
    server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
    accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
    server_admin_password    = module.argocd_bootstrap.argocd_server_admin_password
    domain                   = module.argocd_bootstrap.argocd_domain
    admin_enabled            = true
  }
  base_domain      = module.sks.base_domain
  cluster_issuer   = local.cluster_issuer
  bootstrap_values = module.argocd_bootstrap.bootstrap_values

  helm_values = [{
    argo-cd = {
      server = {
        config = {
          "oidc.tls.insecure.skip.verify" = local.cluster_issuer == "letsencrypt-prod" ? "false" : "true"
        }
      }
    }
  }]

  depends_on = [ module.cert-manager, module.monitoring ]
}

module "my-apps" {
  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git/"

  argocd_namespace = local.argocd_namespace

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
