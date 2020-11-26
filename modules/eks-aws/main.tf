locals {
  base_domain                       = var.base_domain
  kubernetes_host                   = data.aws_eks_cluster.cluster.endpoint
  kubernetes_cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kubernetes_token                  = data.aws_eks_cluster_auth.cluster.token

  kubeconfig = yamlencode(
    merge(
      yamldecode(module.cluster.kubeconfig),
      {
        users = [
          {
            name = lookup(lookup(lookup(yamldecode(module.cluster.kubeconfig), "contexts")[0], "context"), "user")
            user = {
              token = local.kubernetes_token
            }
          }
        ]
      }
    )
  )
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
  ingress_worker_group = merge(var.worker_groups.0, { target_group_arns = concat(module.nlb.target_group_arns, module.nlb_private.target_group_arns) })
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
  source = "../argocd-helm"

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
  dependency_update = true
  create_namespace  = true

  values = [
    templatefile("${path.module}/../../argocd/app-of-apps/values.tmpl.yaml",
      {
        repo_url                        = var.repo_url
        target_revision                 = var.target_revision
        argocd_accounts_pipeline_tokens = module.argocd.argocd_accounts_pipeline_tokens
        extra_apps                      = var.extra_apps
        cluster_name                    = var.cluster_name
        base_domain                     = var.base_domain
        cluster_issuer                  = "letsencrypt-prod"
        client_id                       = aws_cognito_user_pool_client.client.id
        client_secret                   = aws_cognito_user_pool_client.client.client_secret
        admin_password                  = ""
        minio_access_key                = ""
        minio_secret_key                = ""
        enable_efs                      = var.enable_efs
        enable_keycloak                 = false
        enable_olm                      = false
        enable_minio                    = false
      }
    ),
    templatefile("${path.module}/values.tmpl.yaml",
      {
        cluster_name                    = var.cluster_name
        base_domain                     = var.base_domain
        aws_default_region              = data.aws_region.current.name
        cert_manager_assumable_role_arn = module.iam_assumable_role_cert_manager.this_iam_role_arn,
        loki_assumable_role_arn         = module.iam_assumable_role_loki.this_iam_role_arn,
        loki_bucket_name                = aws_s3_bucket.loki.id,
        oidc_issuer_url                 = format("https://cognito-idp.%s.amazonaws.com/%s", data.aws_region.current.name, var.cognito_user_pool_id)
        oauth2_oauth_url                = format("https://%s.auth.%s.amazoncognito.com/oauth2/authorize", var.cognito_user_pool_domain, data.aws_region.current.name)
        oauth2_token_url                = format("https://%s.auth.%s.amazoncognito.com/oauth2/token", var.cognito_user_pool_domain, data.aws_region.current.name)
        oauth2_api_url                  = format("https://%s.auth.%s.amazoncognito.com/oauth2/userInfo", var.cognito_user_pool_domain, data.aws_region.current.name)
        client_id                       = aws_cognito_user_pool_client.client.id
        client_secret                   = aws_cognito_user_pool_client.client.client_secret
        cookie_secret                   = random_password.oauth2_cookie_secret.result
        efs_filesystem_id               = var.enable_efs ? module.efs.0.this_efs_mount_target_file_system_id : ""
        efs_dns_name                    = var.enable_efs ? module.efs.0.this_efs_mount_target_full_dns_name : ""
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.argocd,
  ]
}
