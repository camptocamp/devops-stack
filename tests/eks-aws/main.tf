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

  cognito_user_pool_id     = aws_cognito_user_pool.pool.id
  cognito_user_pool_domain = aws_cognito_user_pool_domain.pool_domain.domain
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
