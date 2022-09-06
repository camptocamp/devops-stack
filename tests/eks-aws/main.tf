locals {
  cluster_issuer = "letsencrypt-staging"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.14.0"
  name                 = module.eks.cluster_name
  cidr                 = "10.56.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.56.1.0/24", "10.56.2.0/24", "10.56.3.0/24"]
  public_subnets       = ["10.56.4.0/24", "10.56.5.0/24", "10.56.6.0/24"]
  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                  = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                           = "1"
  }
}

resource "aws_cognito_user_pool" "pool" {
  name = module.eks.cluster_name
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  domain       = module.eks.cluster_name
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_group" "argocd_admin_group" {
  name         = "argocd-admin"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Users with admin access to Argo CD"
}

/* Available only in provider hashicorp/aws >= v4.0.0
resource "random_string" "admin_password" {
  length  = 25
  special = false
} # TODO create an output for this password

resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.admin.id
  username = admin
  password = random_string.admin_password.result

  message_action = SUPRESS # Do not send welcome message since password is hardcoded and email is non-existant

  attributes = {
    email = "admin@example.org"
    email_verified = true
    terraform = true
  }
}

resource "aws_cognito_user_in_group" "add_admin_argocd_admin" {
  user_pool_id = aws_cognito_user_pool.admin.id
  group_name   = aws_cognito_user_group.argocd_admin_group.name
  username     = aws_cognito_user.admin.username
}
*/

module "eks" {
  source = "git::https://github.com/camptocamp/devops-stack.git//modules/eks/aws?ref=v1"

  cluster_name = "gh-v1-cluster"
  base_domain  = "is-sandbox.camptocamp.com"
  #cluster_version = "1.22"

  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block

  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  node_groups = {
    "${module.eks.cluster_name}-main" = {
      instance_type     = "m5a.large"
      min_size          = 2
      max_size          = 3
      desired_size      = 2
      target_group_arns = module.eks.nlb_target_groups
    },
  }

  create_public_nlb = true
}

provider "kubernetes" {
  host                   = module.eks.kubernetes_host
  cluster_ca_certificate = module.eks.kubernetes_cluster_ca_certificate
  token                  = module.eks.kubernetes_token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.kubernetes_host
    cluster_ca_certificate = module.eks.kubernetes_cluster_ca_certificate
    token                  = module.eks.kubernetes_token
  }
}

locals {
  argocd_namespace = "argocd"
}

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap"

  cluster_name   = module.eks.cluster_name
  base_domain    = module.eks.base_domain
  cluster_issuer = local.cluster_issuer

  depends_on = [module.eks]
}

provider "argocd" {
  server_addr                 = "some.stupid.name.that.doesnt.exist"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = local.argocd_namespace

  kubernetes {
    host                   = module.eks.kubernetes_host
    cluster_ca_certificate = module.eks.kubernetes_cluster_ca_certificate
    token                  = module.eks.kubernetes_token
  }
}

module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//eks"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain

  depends_on = [module.argocd_bootstrap]
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-oidc-aws-cognito.git"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain

  cognito_user_pool_id     = aws_cognito_user_pool.pool.id
  cognito_user_pool_domain = aws_cognito_user_pool_domain.pool_domain.domain

  depends_on = [module.eks]
}

module "thanos" {
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos.git//eks"
  # source = "../../../devops-stack-module-thanos/eks"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain
  cluster_issuer   = local.cluster_issuer

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  thanos = {
    oidc = module.oidc.oidc
  }

  depends_on = [module.argocd_bootstrap]
}

# TODO Discuss renaming the module because we have the monitoring stack mostly separated through multiple modules
module "monitoring" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//eks"
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//eks?ref=chart_upgrade"
  # TODO Remove the ref chart_upgrade

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain
  cluster_issuer   = local.cluster_issuer

  metrics_archives = module.thanos.metrics_archives

  prometheus = {
    oidc = module.oidc.oidc
  }
  alertmanager = {
    oidc = module.oidc.oidc
  }
  grafana = {
    # enable = false # Optional
    additional_data_sources = true
  }

  depends_on = [module.argocd_bootstrap, module.thanos]
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//eks"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  depends_on = [module.monitoring]
}

module "grafana" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-grafana.git"
  source = "git::https://github.com/camptocamp/devops-stack-module-grafana.git?ref=troubleshoot_deployment"
  # TODO Remove the ref troubleshoot_deployment

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain

  grafana = {
    oidc = module.oidc.oidc
  }

  depends_on = [module.monitoring, module.loki-stack]
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//eks"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  depends_on = [module.monitoring]
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git"

  cluster_name = module.eks.cluster_name
  oidc = {
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
  argocd = {
    namespace                = local.argocd_namespace
    server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
    accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
    server_admin_password    = module.argocd_bootstrap.argocd_server_admin_password
    domain                   = module.argocd_bootstrap.argocd_domain
  }
  base_domain      = module.eks.base_domain
  cluster_issuer   = local.cluster_issuer
  bootstrap_values = module.argocd_bootstrap.bootstrap_values
  #  repositories = {
  #    "argocd" = {
  #    url      = local.repo_url
  #    revision = local.target_revision
  #  }}

  depends_on = [module.cert-manager, module.monitoring]
}

resource "argocd_application" "metrics-server" {
  metadata {
    name      = "metrics-server"
    namespace = local.argocd_namespace
  }

  wait = true

  spec {
    # TODO Discuss on the next weekly if we shouldn't put this on its own 
    # Argo CD project like all the other intrinsic cluster applications 
    # we deploy. To do that we either add an argocd_project resource or 
    # I propose we create a module not for metrics-server itself but to deploy 
    # applications that do not need an application set like the other module 
    # below.
    project = "default"

    source {
      repo_url        = "https://github.com/kubernetes-sigs/metrics-server.git/"
      path            = "charts/metrics-server"
      target_revision = "master"
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "kube-system"
    }

    sync_policy {
      automated = {
        allow_empty = false
        self_heal   = true
        prune       = true
      }
      sync_options = [
        "CreateNamespace=true"
      ]
    }
  }

  depends_on = [module.argocd]

}

module "helloworld" {
  source           = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git/"
  name             = "apps"
  argocd_namespace = "argocd"
  namespace        = "helloworld"

  depends_on = [module.argocd]

  generators = [
    {
      git = {
        repoURL  = "https://github.com/camptocamp/devops-stack-helloworld-templates.git/"
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
      project = "default"

      source = {
        repoURL        = "https://github.com/camptocamp/devops-stack-helloworld-templates.git/"
        targetRevision = "main"
        path           = "{{path}}"

        helm = {
          valueFiles = []
          # The following value defines this global variables that will be available to all apps in apps/*
          # This apps needs these to generate the ingresses containing the name and base domain of the cluster. 
          values = <<-EOT
            cluster:
              name: "${module.eks.cluster_name}"
              domain: "${module.eks.base_domain}"
            apps:
              traefik_dashboard: false # TODO Add variable when we configure the Thanos Dashboard
              grafana: ${module.grafana.grafana_enabled || module.monitoring.grafana_enabled}
              prometheus: ${module.monitoring.prometheus_enabled}
              thanos: ${module.thanos.thanos_enabled}
              alertmanager: ${module.monitoring.alertmanager_enabled}
          EOT
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
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

/*
# This module here has a slight variation on the definition above.
# What happens is: this module defines an application set (saved in the argocd namespace) that then
# iterates over each folder in apps/*, creating a namespace for each one and in each one of
# those namespaces it creates another another application set that takes the chart inside the 
# folder charts and the definition inside charts/projects.

### Chart.yaml
# apiVersion: v2
# appVersion: "1.0"
# description: projects
# name: projects
# version: 1.0.0

### applicationset.yaml
# ---
# apiVersion: argoproj.io/v1alpha1
# kind: ApplicationSet
# metadata:
#   annotations:
#     argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
#   name: {{ $.Values.project_name }}
#   namespace: argocd
# spec:
#   generators:
#   - git:
#       directories:
#       - path: apps/{{ $.Values.project_name }}/*
#       repoURL: git@gitlab.com:camptocamp/is/shared-services/argo-cd.git
#       revision: HEAD
#   template:
#     metadata:
#       name: {{ printf "%s-%s" $.Values.project_name "{{path.basename}}" }}
#     spec:
#       destination:
#         namespace: {{ $.Values.project_name }}
#         server: https://kubernetes.default.svc
#       project: default
#       source:
#         helm:
#           valueFiles:
#           - values.yaml
#           - secrets.yaml
#         path: {{ "'{{path}}'" }}
#         repoURL: git@gitlab.com:camptocamp/is/shared-services/argo-cd.git
#         targetRevision: HEAD
#       syncPolicy:
#         automated: 
#           selfHeal: true
#           prune: true
#         syncOptions:
#           - CreateNamespace=true

module "helloworld" {
  source           = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git/"
  name             = "apps"
  argocd_namespace = "argocd"
  namespace        = "argocd"
  generators = [
    {
      git = {
        repoURL  = "https://github.com/lentidas/devops-stack-helloworld-templates"
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
      project = "default"

      source = {
        repoURL        = "https://github.com/lentidas/devops-stack-helloworld-templates"
        targetRevision = "main"
        path           = "charts/projects"

        helm = {
          valueFiles = []
          values     = <<-EOT
            project_name: "{{path.basename}}"
          EOT
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "{{path.basename}}"
      }
      
      syncPolicy = {
        automated = {
          selfHeal = true
          prune    = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}
*/
