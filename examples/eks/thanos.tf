resource "aws_s3_bucket" "thanos" {
  bucket = format("%s-thanos", module.eks.cluster_name)
}

module "iam_assumable_role_thanos" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                    = "4.0.0"
  create_role                = true
  number_of_role_policy_arns = 1
  role_name                  = format("thanos-s3-%s", module.eks.cluster_name)
  provider_url               = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns           = [aws_iam_policy.thanos_s3.arn]

  # List of ServiceAccounts that have permission to attach to this IAM role
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:thanos:thanos-bucketweb",
    "system:serviceaccount:thanos:thanos-compactor",
    "system:serviceaccount:thanos:thanos-storegateway",
  ]
}

resource "aws_iam_policy" "thanos_s3" {
  name_prefix = format("%s-thanos-s3", module.eks.cluster_name)

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
          aws_s3_bucket.thanos.arn,
          "${aws_s3_bucket.thanos.arn}/*",
        ]
      },
    ]
  })
}

module "thanos" {
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos.git//eks?ref=v2.0.1"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.eks.base_domain
  cluster_issuer   = local.cluster_issuer

  metrics_storage = {
    bucket_id    = aws_s3_bucket.thanos.id
    region       = aws_s3_bucket.thanos.region
    iam_role_arn = module.iam_assumable_role_thanos.iam_role_arn
  }

  thanos = {
    oidc = module.oidc.oidc
  }

  depends_on = [module.argocd_bootstrap]
}
