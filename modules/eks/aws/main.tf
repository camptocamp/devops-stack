locals {
  base_domain                       = coalesce(var.base_domain, format("%s.nip.io", replace(data.dns_a_record_set.nlb.addrs[0], ".", "-")))
  kubernetes_host                   = data.aws_eks_cluster.cluster.endpoint
  kubernetes_cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kubernetes_token                  = data.aws_eks_cluster_auth.cluster.token
  kubeconfig                        = module.cluster.kubeconfig
  cluster_issuer          = "letsencrypt-prod"
}

data "aws_region" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.this.id

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.this.id

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

data "aws_route53_zone" "this" {
  count = var.base_domain == null ? 0 : 1

  name = var.base_domain
}

data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster_id
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
    token                  = local.kubernetes_token
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  token                  = local.kubernetes_token
}

locals {
  ingress_worker_group = merge(var.worker_groups.0, { target_group_arns = concat(module.nlb.target_group_arns, module.nlb_private.target_group_arns) })
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "15.1.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  subnets          = data.aws_subnet_ids.private.ids
  vpc_id           = var.vpc_id
  enable_irsa      = true
  write_kubeconfig = false
  map_accounts     = var.map_accounts
  map_roles        = var.map_roles
  map_users        = var.map_users

  worker_groups = concat([local.ingress_worker_group], try(slice(var.worker_groups, 1, length(var.worker_groups)), []))

  kubeconfig_aws_authenticator_command      = var.kubeconfig_aws_authenticator_command
  kubeconfig_aws_authenticator_command_args = var.kubeconfig_aws_authenticator_command_args
}

resource "aws_security_group_rule" "workers_ingress_healthcheck_https" {
  security_group_id = module.cluster.worker_security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
}
resource "aws_security_group_rule" "workers_ingress_healthcheck_http" {
  security_group_id = module.cluster.worker_security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
}

module "argocd" {
  source = "../../argocd-helm"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  extra_app_projects      = var.extra_app_projects
  extra_application_sets  = var.extra_application_sets
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  argocd_server_secretkey = var.argocd_server_secretkey
  cluster_issuer          = local.cluster_issuer

  # loki = {
  #   bucket_name = aws_s3_bucket.loki.id,
  # }

  cluster_autoscaler = {
    enable = var.enable_cluster_autoscaler
  }

  repositories = var.repositories

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        aws_default_region              = data.aws_region.current.name
        base_domain                     = local.base_domain
        enable_efs                      = var.enable_efs
        efs_filesystem_id               = var.enable_efs ? module.efs.0.this_efs_mount_target_file_system_id : ""
        efs_dns_name                    = var.enable_efs ? module.efs.0.this_efs_mount_target_full_dns_name : ""
        cluster_name                    = var.cluster_name
        cluster_autoscaler_role_arn     = var.enable_cluster_autoscaler ? module.iam_assumable_role_cluster_autoscaler[0].iam_role_arn : ""
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
  ]
}
