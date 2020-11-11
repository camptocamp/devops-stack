locals {
  base_domain                       = var.base_domain
  kubernetes_host                   = data.aws_eks_cluster.cluster.endpoint
  kubernetes_cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kubernetes_token                  = data.aws_eks_cluster_auth.cluster.token
}

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

data "aws_nat_gateway" "this" {
  for_each  = data.aws_subnet_ids.public.ids
  subnet_id = each.value
  state     = "available"
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
    load_config_file       = false
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  token                  = local.kubernetes_token
  load_config_file       = false
}

locals {
  ingress_worker_group = merge(var.worker_groups.0, { target_group_arns = module.nlb.target_group_arns })
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "13.1.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.18"

  cluster_endpoint_public_access_cidrs = concat(
    [
      for nat_gateway in data.aws_nat_gateway.this :
      format("%s/32", nat_gateway.public_ip)
    ],
    var.cluster_endpoint_public_access_cidrs
  )

  subnets          = data.aws_subnet_ids.private.ids
  vpc_id           = var.vpc_id
  enable_irsa      = true
  write_kubeconfig = false
  map_roles        = var.map_roles

  worker_groups = length(var.worker_groups) > 1 ? flatten([local.ingress_worker_group, slice(var.worker_groups, 1, length(var.worker_groups)), ]) : [local.ingress_worker_group]

  kubeconfig_aws_authenticator_command = var.kubeconfig_aws_authenticator_command
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

resource "helm_release" "argocd" {
  name              = "argocd"
  chart             = "${path.module}/../../argocd/argocd"
  namespace         = "argocd"
  #dependency_update = true
  create_namespace  = true

  values = [
    file("${path.module}/../../argocd/argocd/values.yaml")
  ]

  depends_on = [
    module.cluster,
  ]
}

resource "random_password" "oauth2_cookie_secret" {
  length  = 16
  special = false
}

resource "helm_release" "app_of_apps" {
  name              = "app-of-apps"
  chart             = "${path.module}/../../argocd/app-of-apps"
  namespace         = "argocd"
  #dependency_update = true
  create_namespace  = true

  values = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        cluster_name                    = var.cluster_name,
        base_domain                     = var.base_domain,
        repo_url                        = var.repo_url,
        target_revision                 = var.target_revision,
        aws_default_region              = data.aws_region.current.name,
        cert_manager_assumable_role_arn = module.iam_assumable_role_cert_manager.this_iam_role_arn,
        cognito_user_pool_id            = var.cognito_user_pool_id
        cognito_user_pool_client_id     = aws_cognito_user_pool_client.client.id
        cognito_user_pool_client_secret = aws_cognito_user_pool_client.client.client_secret
        cookie_secret                   = random_password.oauth2_cookie_secret.result
        enable_efs                      = var.enable_efs
        efs_filesystem_id               = var.enable_efs ? module.efs.0.file_system_id : ""
        efs_dns_name                    = var.enable_efs ? module.efs.0.full_dns_name : ""
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    helm_release.argocd,
  ]
}
