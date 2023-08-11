locals {
  s3_buckets = [
    "longhorn",
    "loki",
    "thanos",
  ]
}

resource "aws_s3_bucket" "this" {
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

resource "exoscale_iam_access_key" "s3_iam_key" {
  for_each = toset(local.s3_buckets)

  name      = "${local.cluster_name}-${each.key}-s3-iam-key"
  resources = ["sos/bucket:${local.cluster_name}-${each.key}"]

  # Probably not all these permissions are needed. However, these IAM keys are resource-scoped, so there should be no 
  # issue. The only SOS permissions commented out are the ones related to the creation and deletion of an SOS bucket.
  operations = [
    "abort-sos-multipart-upload",
    "by-pass-sos-governance-retention",
    # "create-sos-bucket",
    # "delete-sos-bucket",
    "delete-sos-object",
    "get-sos-bucket-acl",
    "get-sos-bucket-cors",
    "get-sos-bucket-location",
    "get-sos-bucket-object-lock-configuration",
    "get-sos-bucket-ownership-controls",
    "get-sos-bucket-versioning",
    "get-sos-object",
    "get-sos-object-acl",
    "get-sos-object-legal-hold",
    "get-sos-object-retention",
    "get-sos-presigned-url",
    "list-sos-bucket",
    "list-sos-bucket-multipart-uploads",
    "list-sos-bucket-versions",
    "list-sos-buckets",
    "list-sos-buckets-usage",
    "put-sos-bucket-acl",
    "put-sos-bucket-cors",
    "put-sos-bucket-object-lock-configuration",
    "put-sos-bucket-ownership-controls",
    "put-sos-bucket-versioning",
    "put-sos-object",
    "put-sos-object-acl",
    "put-sos-object-legal-hold",
    "put-sos-object-retention",
  ]

  depends_on = [
    aws_s3_bucket.this,
  ]
}
