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
    "kubernetes.io/role/internal-elb"           = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_cognito_user_pool" "pool" {
  name = module.eks.cluster_name
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  domain       = module.eks.cluster_name
  user_pool_id = aws_cognito_user_pool.pool.id
}

module "eks" {
  source = "../../modules/eks/aws"

  cluster_name = "ckg-v1test"
  base_domain  = "is-sandbox.camptocamp.com"

  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block

  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids = module.vpc.public_subnets

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

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain
}

provider "argocd" {
  server_addr = "some.stupid.name.that.doesnt.exist"
  auth_token  = module.argocd_bootstrap.argocd_auth_token
  insecure = true
  plain_text = true
  port_forward = true
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
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-oidc-aws-cognito.git/"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain

  cognito_user_pool_id     = aws_cognito_user_pool.pool.id
  cognito_user_pool_domain = aws_cognito_user_pool_domain.pool_domain.domain
}

module "monitoring" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git/"

  cluster_name     = module.eks.cluster_name
  oidc             = module.oidc.oidc
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain
  cluster_issuer   = "letsencrypt-prod"
  metrics_archives = {}

  depends_on = [ module.oidc ]
}

#module "loki-stack" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//eks"
#
#  cluster_name     = module.eks.cluster_name
#  argocd_namespace = local.argocd_namespace
#  base_domain      = module.cluster.base_domain
#
#  cluster_oidc_issuer_url = module.cluster.cluster_oidc_issuer_url
#
#  depends_on = [ module.monitoring ]
#}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//eks"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  #depends_on = [ module.monitoring ]
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git/"

  cluster_name   = module.eks.cluster_name
  oidc           = module.oidc.oidc
  argocd         = {
    namespace = local.argocd_namespace
    server_secretkey = module.argocd_bootstrap.argocd_server_secretkey
    accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
    server_admin_password = module.argocd_bootstrap.argocd_server_admin_password
    domain = module.argocd_bootstrap.argocd_domain
  }
  base_domain    = module.eks.base_domain
  cluster_issuer = "letsencrypt-prod"

#  repositories = {
#    "argocd" = {
#    url      = local.repo_url
#    revision = local.target_revision
#  }}

  depends_on = [ module.cert-manager, module.monitoring ]
}

##module "myownapp" {
##  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git/"
##
##  cluster_name   = module.eks.cluster_name
##  oidc           = module.oidc.oidc
##  argocd         = {
##    server     = module.cluster.argocd_server
##    auth_token = module.cluster.argocd_auth_token
##  }
##  base_domain    = module.cluster.base_domain
##  cluster_issuer = module.cluster.cluster_issuer
##
##  argocd_url = "https://github.com/camptocamp/myapp.git"
##}
