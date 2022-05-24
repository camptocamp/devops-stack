locals {
  all_domains = toset(compact(distinct(concat([var.base_domain], var.other_domains)))) 
} 

data "aws_route53_zone" "this" {
  for_each = local.all_domains

   name = each.key
}

data "aws_region" "current" {}

module "iam_assumable_role_cert_manager" {
  count = length(local.all_domains) == 0 ? 0 : 1

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.0.0"
  create_role                   = true
  role_name                     = format("cert-manager-%s", var.cluster_name)
  provider_url                  = replace(module.cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [for domain in local.all_domains : aws_iam_policy.cert_manager[domain].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]
}

resource "aws_iam_policy" "cert_manager" {
  for_each = local.all_domains

  name_prefix = "cert-manager"
  description = "EKS cert-manager policy for cluster ${module.cluster.cluster_id}"
  policy = data.aws_iam_policy_document.cert_manager[each.key].json
}

data "aws_iam_policy_document" "cert_manager" {
  for_each = local.all_domains

  statement {
    actions = [
      "route53:ListHostedZonesByName"
    ]

    resources = [
      "*"
    ]

    effect = "Allow"
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]

    resources = [
      format("arn:aws:route53:::hostedzone/%s", data.aws_route53_zone.this[each.key].id),
    ]

    effect = "Allow"
  }

  statement {
    actions = [
      "route53:GetChange"
    ]

    resources = [
      "arn:aws:route53:::change/*"
    ]

    effect = "Allow"
  }
}
