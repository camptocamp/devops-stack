data "aws_availability_zones" "available" {}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.2.0"
  name                 = var.cluster_name
  cidr                 = "10.56.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.56.1.0/24", "10.56.2.0/24", "10.56.3.0/24"]
  public_subnets       = ["10.56.4.0/24", "10.56.5.0/24", "10.56.6.0/24"]
  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_cognito_user_pool" "pool" {
  name = var.cluster_name
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  domain       = var.cluster_name
  user_pool_id = aws_cognito_user_pool.pool.id
}

module "cluster" {
  source = "../../modules/eks/aws"

  cluster_name = var.cluster_name
  base_domain = "demo.camptocamp.com"
  vpc_id       = module.vpc.vpc_id

  cluster_endpoint_public_access_cidrs = flatten([
    formatlist("%s/32", module.vpc.nat_public_ips),
    "0.0.0.0/0",
  ])

  worker_groups = [
    {
      instance_type        = "m5a.large"
      asg_desired_capacity = 2
      asg_max_size         = 3
      root_volume_type     = "gp2"
    },
  ]

  repo_url        = var.repo_url
  target_revision = var.target_revision
}


resource "aws_security_group_rule" "workers_ingress_public_access_https" {
  security_group_id = module.cluster.worker_security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "workers_ingress_public_access_http" {
  security_group_id = module.cluster.worker_security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}


provider "argocd" {
  server_addr = "127.0.0.1:8080"
  auth_token  = module.cluster.argocd_auth_token
  insecure = true
  plain_text = true
  port_forward = true
  port_forward_with_namespace = module.cluster.argocd_namespace

  kubernetes {
    host                   = module.cluster.kubernetes_host
    cluster_ca_certificate = module.cluster.kubernetes_cluster_ca_certificate
    token = module.cluster.kubernetes_token
  }
}

module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//modules/eks"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-oidc-aws-cognito.git//modules"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain    = module.cluster.base_domain

  cognito_user_pool_id     = aws_cognito_user_pool.pool.id
  cognito_user_pool_domain = aws_cognito_user_pool_domain.pool_domain.domain
}

module "monitoring" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//modules"

  cluster_name     = var.cluster_name
  oidc             = module.oidc.oidc
  argocd_namespace = module.cluster.argocd_namespace
  base_domain    = module.cluster.base_domain
  cluster_issuer = "letsencrypt-prod"
  metrics_archives = {}

  depends_on = [ module.oidc ]
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//modules/eks"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  cluster_oidc_issuer_url = module.cluster.cluster_oidc_issuer_url

  depends_on = [ module.monitoring ]
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//modules/eks"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  cluster_oidc_issuer_url = module.cluster.cluster_oidc_issuer_url

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
  }
  base_domain    = module.cluster.base_domain
  cluster_issuer = "letsencrypt-prod"

  depends_on = [ module.cert-manager, module.monitoring ]
}

#module "myownapp" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git//modules"
#
#  cluster_name   = module.cluster.cluster_name
#  oidc           = module.oidc.oidc
#  argocd         = {
#    server     = module.cluster.argocd_server
#    auth_token = module.cluster.argocd_auth_token
#  }
#  base_domain    = module.cluster.base_domain
#  cluster_issuer = module.cluster.cluster_issuer
#
#  argocd_url = "https://github.com/camptocamp/myapp.git"
#}
