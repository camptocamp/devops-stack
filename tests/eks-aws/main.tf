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

  depends_on = [module.cert-manager, module.monitoring, module.grafana]
}

module "metrics_server" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-application.git"
  source = "git::https://github.com/camptocamp/devops-stack-module-application.git?ref=initial_development"
  # TODO Remove ref to initial_deployment

  name             = "metrics-server"
  argocd_namespace = local.argocd_namespace

  source_repo            = "https://github.com/kubernetes-sigs/metrics-server.git"
  source_repo_path       = "charts/metrics-server"
  source_target_revision = "master"
  destination_namespace  = "kube-system"

  depends_on = [module.argocd]
}

module "helloworld_apps" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git"
  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git?ref=applicationset_modifs"
  # TODO Remove ref to applicationset_modifs

  depends_on = [module.argocd]

  name                   = "helloworld-apps"
  argocd_namespace       = local.argocd_namespace
  project_dest_namespace = "*"
  project_source_repos = [
    "https://github.com/camptocamp/devops-stack-helloworld-templates.git",
  ]

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
              name: "${module.eks.cluster_name}"
              domain: "${module.eks.base_domain}"
            apps:
              traefik_dashboard: false # TODO Add variable when we configure the Traefik Dashboard
              grafana: ${module.grafana.grafana_enabled || module.monitoring.grafana_enabled}
              prometheus: ${module.monitoring.prometheus_enabled}
              thanos: ${module.thanos.thanos_enabled}
              alertmanager: ${module.monitoring.alertmanager_enabled}
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
