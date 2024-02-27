locals {
  kubernetes_version       = "1.29"
  cluster_name             = "YOUR_CLUSTER_NAME" # Must be unique for each DevOps Stack deployment in a single AWS account. Contains only alphanumeric and hyphens.
  base_domain              = "your.domain.here"  # Must match a Route 53 zone in the AWS account where you are deploying the DevOps Stack.
  subdomain                = "apps"
  cluster_issuer           = module.cert-manager.cluster_issuers.staging
  letsencrypt_issuer_email = "YOUR_EMAIL_ADDRESS"
  enable_service_monitor   = false # Can be enabled after the first bootstrap.
  app_autosync             = true ? { allow_empty = false, prune = true, self_heal = true } : {}

  # The VPC CIDR must be unique for each DevOps Stack deployment in a single AWS account.
  vpc_cidr = "10.56.0.0/16"
  # Automatic subnets IP range calculation, splitting the vpc_cidr above into 6 subnets.
  private_subnets_cidr = cidrsubnet(local.vpc_cidr, 1, 0)
  public_subnets_cidr  = cidrsubnet(local.vpc_cidr, 1, 1)
  private_subnets      = cidrsubnets(local.private_subnets_cidr, 2, 2, 2)
  public_subnets       = cidrsubnets(local.public_subnets_cidr, 2, 2, 2)
}
