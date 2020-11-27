resource "aws_s3_bucket" "thanos" {
  tags = {
    Name        = "Thanos"
    Environment = var.cluster_name
  }
}

module "iam_assumable_role_thanos" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.3.0"
  create_role                   = true
  number_of_role_policy_arns    = 1
  role_name                     = format("thanos-%s", var.cluster_name)
  provider_url                  = replace(module.cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.thanos.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-prometheus-stack:kube-prometheus-stack-prometheus"]
}

resource "aws_iam_policy" "thanos" {
  name_prefix = "thanos"
  description = "EKS thanos policy for cluster ${module.cluster.cluster_id}"
  policy      = data.aws_iam_policy_document.thanos.json
}

data "aws_iam_policy_document" "thanos" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.thanos.arn,
      format("%s/*", aws_s3_bucket.thanos.arn),
    ]

    effect = "Allow"
  }
}
