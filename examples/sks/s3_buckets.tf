locals {
  s3_buckets = [
    "longhorn",
    "loki",
    "thanos",
  ]
}

resource "aws_s3_bucket" "this" {
  provider = aws.exoscale-s3

  for_each = toset(local.s3_buckets)

  bucket        = "${local.cluster_name}-${each.key}"
  force_destroy = true

  lifecycle {
    ignore_changes = [
      object_lock_configuration,
      tags,
    ]
  }
}

# Role based on the example available https://github.com/exoscale/terraform-provider-exoscale/blob/28da8e40dca37d93e4f3438f3bf906ef400f5b07/examples/iam-bucket-access/main.tf
resource "exoscale_iam_role" "s3_role" {
  for_each = toset(local.s3_buckets)

  name        = "${local.cluster_name}-${each.key}-s3-role"
  description = "Role for SOS bucket ${each.key} for the ${local.cluster_name} SKS cluster. Created using Terraform."
  editable    = true

  policy = {
    default_service_strategy = "deny"
    services = {
      sos = {
        # These rules are used in order, so if a rule does not match, the following rules are NOT evaluated.
        # In these settings, we first allow all operations except create-bucket and delete-bucket, then we deny all
        # operations on buckets that are not the one that the role relates to.
        type = "rules"
        rules = [
          {
            expression = "!(operation in ['create-bucket', 'delete-bucket'])"
            action     = "allow"
          },
          {
            expression = "!(parameters.bucket in ['${each.key}'])"
            action     = "deny"
          },
        ]
      }
    }
  }
}

resource "exoscale_iam_api_key" "s3_iam_api_key" {
  for_each = toset(local.s3_buckets)

  name    = "${local.cluster_name}-${each.key}-s3-iam-key"
  role_id = resource.exoscale_iam_role.s3_role[each.key].id

  depends_on = [
    resource.aws_s3_bucket.this,
  ]
}
