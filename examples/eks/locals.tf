locals {
  cluster_issuer   = "letsencrypt-staging"
  argocd_namespace = "argocd" # Argo CD is deployed by default inside the namespace `argocd` but we need to tell this to the other modules.

  # The base_domain must match a Route53 zone in the AWS account where you are deploying the DevOps Stack
  base_domain  = "is-sandbox.camptocamp.com"

  # These two values must be unique for each DevOps Stack deployment in a single AWS account
  cluster_name = "example-eks"
  vpc_cidr     = "10.56.0.0/16"


  # Automatic subnets IP range calculation, splitting the vpc_cidr above into 6 subnets
  private_subnets_cidr = cidrsubnet(local.vpc_cidr, 1, 0)
  public_subnets_cidr  = cidrsubnet(local.vpc_cidr, 1, 1)
  private_subnets      = cidrsubnets(local.private_subnets_cidr, 2, 2, 2)
  public_subnets       = cidrsubnets(local.public_subnets_cidr, 2, 2, 2)
}
