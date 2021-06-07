locals {
  base_domain = "example.com"

  kubernetes_host                   = module.cluster.kubernetes_host
  kubernetes_cluster_ca_certificate = module.cluster.kubernetes_cluster_ca_certificate
  kubernetes_token                  = module.cluster.kubernetes_token

  map_roles = [
    {
      rolearn  = data.aws_iam_role.eks_admin.arn
      username = data.aws_iam_role.eks_admin.arn
      groups   = ["system:masters"]
    },
  ]
}

data "aws_vpc" "this" {
  cidr_block = "10.11.0.0/16"
}

data "aws_iam_role" "eks_admin" {
  name = "eks_admin"
}

module "cluster" {
  source = "git::https://github.com/camptocamp/devops-stack.git//modules/eks/aws?ref=v0.35.0"

  cluster_name                         = "my-cluster"
  cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs
  vpc_id                               = data.aws_vpc.this.id

  worker_groups = [
    {
      instance_type        = "m5a.large"
      asg_desired_capacity = 2
      asg_max_size         = 3
    }
  ]

  map_roles = local.map_roles

  base_domain = local.base_domain

  cognito_user_pool_id     = aws_cognito_user_pool.pool.id
  cognito_user_pool_domain = aws_cognito_user_pool_domain.pool_domain.domain
}

resource "aws_cognito_user_pool" "pool" {
  name = "pool"
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  domain       = "pool-domain"
  user_pool_id = aws_cognito_user_pool.pool.id
}
