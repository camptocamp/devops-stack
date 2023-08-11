resource "aws_s3_bucket" "loki" {
  bucket = format("%s-loki", module.eks.cluster_name)
}

module "iam_assumable_role_loki" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                    = "4.0.0"
  create_role                = true
  number_of_role_policy_arns = 1
  role_name                  = format("loki-s3-%s", module.eks.cluster_name)
  provider_url               = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns           = [aws_iam_policy.loki_s3.arn]

  # List of ServiceAccounts that have permission to attach to this IAM role
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:loki-stack:loki"
  ]
}

resource "aws_iam_policy" "loki_s3" {
  name_prefix = format("%s-loki-s3", module.eks.cluster_name)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.loki.arn,
          "${aws_s3_bucket.loki.arn}/*",
        ]
      },
    ]
  })
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//eks?ref=v4.0.2"

  argocd_namespace = local.argocd_namespace

  logs_storage = {
    bucket_id    = aws_s3_bucket.loki.id
    region       = aws_s3_bucket.loki.region
    iam_role_arn = module.iam_assumable_role_loki.iam_role_arn
  }

  depends_on = [module.prometheus-stack]
}


