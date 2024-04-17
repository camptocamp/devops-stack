resource "aws_s3_bucket" "loki_logs_storage" {
  bucket = format("loki-logs-storage-%s", module.eks.cluster_name)

  force_destroy = true

  tags = {
    Description = "Loki logs storage"
    Cluster     = module.eks.cluster_name
  }
}

module "iam_assumable_role_loki" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                    = "~> 5.0"
  create_role                = true
  number_of_role_policy_arns = 1
  role_name_prefix           = format("loki-s3-%s-", local.cluster_name)
  provider_url               = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns           = [resource.aws_iam_policy.loki_s3_policy.arn]

  # List of ServiceAccounts that have permission to attach to this IAM role
  oidc_fully_qualified_subjects = [
    # ServiceAccount for Loki standard 
    "system:serviceaccount:loki-stack:loki-stack",
    # ServiceAccounts for Loki distributed
    "system:serviceaccount:loki-stack:loki",
  ]
}

resource "aws_iam_policy" "loki_s3_policy" {
  name_prefix = "loki-s3-"
  description = "Loki IAM policy for cluster ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.loki_s3_policy.json
}

# As per https://grafana.com/docs/loki/latest/operations/storage/#s3
data "aws_iam_policy_document" "loki_s3_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.loki_logs_storage.arn,
      format("%s/*", aws_s3_bucket.loki_logs_storage.arn),
    ]

    effect = "Allow"
  }
}
