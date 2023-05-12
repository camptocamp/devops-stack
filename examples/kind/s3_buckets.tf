resource "random_password" "loki_secretkey" {
  length  = 32
  special = false
}
resource "random_password" "thanos_secretkey" {
  length  = 32
  special = false
}

locals {
  minio_config = {
    policies = [
      {
        name = "loki-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::loki-bucket"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::loki-bucket/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "thanos-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::thanos-bucket"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::thanos-bucket/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      }
    ],
    users = [
      {
        accessKey = "loki-user"
        secretKey = random_password.loki_secretkey.result
        policy    = "loki-policy"
      },
      {
        accessKey = "thanos-user"
        secretKey = random_password.thanos_secretkey.result
        policy    = "thanos-policy"
      }
    ],
    buckets = [
      {
        name = "loki-bucket"
      },
      {
        name = "thanos-bucket"
      }
    ]
  }
}
