resource "aws_s3_bucket" "thanos_metrics_storage" {
  bucket = format("thanos-metrics-storage-%s", module.eks.cluster_name)

  force_destroy = true

  tags = {
    Name    = "Thanos metrics storage"
    Cluster = module.eks.cluster_name
  }
}

module "iam_assumable_role_thanos" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                    = "4.0.0"
  create_role                = true
  number_of_role_policy_arns = 1
  role_name                  = format("thanos-s3-role-%s", module.eks.cluster_name)
  provider_url               = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns           = [aws_iam_policy.thanos_s3_policy.arn]

  # List of ServiceAccounts that have permission to attach to this IAM role
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:thanos:thanos-bucketweb",
    "system:serviceaccount:thanos:thanos-storegateway",
    "system:serviceaccount:thanos:thanos-compactor",
    "system:serviceaccount:thanos:thanos-sidecar",
    "system:serviceaccount:kube-prometheus-stack:kube-prometheus-stack-prometheus"
  ]
}

resource "aws_iam_policy" "thanos_s3_policy" {
  name_prefix = "thanos-s3-"
  description = "Thanos IAM policy for cluster ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.thanos_s3_policy.json
}

data "aws_iam_policy_document" "thanos_s3_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.thanos_metrics_storage.arn,
      format("%s/*", aws_s3_bucket.thanos_metrics_storage.arn),
    ]

    effect = "Allow"
  }
}
