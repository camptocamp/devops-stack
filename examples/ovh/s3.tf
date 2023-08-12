########################################################################################
#     User / Credential
########################################################################################
resource "ovh_cloud_project_user" "s3_admin_user" {
  description = "user that is used to create S3 bucket"
  role_name   = "objectstore_operator"
}

resource "ovh_cloud_project_user_s3_credential" "s3_admin_cred" {
  user_id = ovh_cloud_project_user.s3_admin_user.id
}


################  LOKI  ################
resource "ovh_cloud_project_user" "loki_write_user" {
  description = "loki_write_user that will have write access to the bucket"
  role_name   = "objectstore_operator"
}
resource "ovh_cloud_project_user_s3_credential" "loki_write_cred" {
  user_id = ovh_cloud_project_user.loki_write_user.id
}

resource "ovh_cloud_project_user" "loki_read_user" {
  description = "loki_read_user that will have read access to the bucket"
  role_name   = "objectstore_operator"
}
resource "ovh_cloud_project_user_s3_credential" "loki_read_cred" {
  user_id = ovh_cloud_project_user.loki_read_user.id
}

################  THANOS  ################
resource "ovh_cloud_project_user" "thanos_write_user" {
  description = "thanos_write_user that will have write access to the bucket"
  role_name   = "objectstore_operator"
}
resource "ovh_cloud_project_user_s3_credential" "thanos_write_cred" {
  user_id = ovh_cloud_project_user.thanos_write_user.id
}

resource "ovh_cloud_project_user" "thanos_read_user" {
  description = "thanos_read_user that will have read access to the bucket"
  role_name   = "objectstore_operator"
}
resource "ovh_cloud_project_user_s3_credential" "thanos_read_cred" {
  user_id = ovh_cloud_project_user.thanos_read_user.id
}

########################################################################################
#     Bucket
########################################################################################

################  LOKI  ################

resource "aws_s3_bucket" "loki_bucket" {
  bucket = "${var.OVH_CLOUD_PROJECT_SERVICE}-${var.CLUSTER_PREFIX}-${var.ENV_FOR_DOMAIN}-loki-bucket"
}

################  THANOS  ################

resource "aws_s3_bucket" "thanos_bucket" {
  bucket = "${var.OVH_CLOUD_PROJECT_SERVICE}-${var.CLUSTER_PREFIX}-${var.ENV_FOR_DOMAIN}-thanos-bucket"
}

########################################################################################
#     Policy
########################################################################################

################  LOKI  ################

resource "ovh_cloud_project_user_s3_policy" "loki_write_policy" {
  user_id = ovh_cloud_project_user.loki_write_user.id
  policy = jsonencode({
    "Statement" : [
      {
        resources = ["arn:aws:s3:::${aws_s3_bucket.loki_bucket.bucket}"]
        actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
      },
      {
        resources = ["arn:aws:s3:::${aws_s3_bucket.loki_bucket.bucket}/*"]
        actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      }
    ]
  })
}


resource "ovh_cloud_project_user_s3_policy" "loki_read_policy" {
  user_id = ovh_cloud_project_user.loki_read_user.id
  policy = jsonencode({
    "Statement" : [{
      "Sid" : "ROContainer",
      "Effect" : "Allow",
      "Action" : ["s3:GetObject", "s3:ListBucket", "s3:ListMultipartUploadParts", "s3:ListBucketMultipartUploads"],
      "Resource" : ["arn:aws:s3:::${aws_s3_bucket.loki_bucket.bucket}", "arn:aws:s3:::${aws_s3_bucket.loki_bucket.bucket}/*"]
    }]
  })
}

################  THANOS  ################

resource "ovh_cloud_project_user_s3_policy" "thanos_write_policy" {
  user_id = ovh_cloud_project_user.thanos_write_user.id
  policy = jsonencode({
    "Statement" : [
      {
        resources = ["arn:aws:s3:::${aws_s3_bucket.thanos_bucket.bucket}"]
        actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
      },
      {
        resources = ["arn:aws:s3:::${aws_s3_bucket.thanos_bucket.bucket}/*"]
        actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      }
    ]
  })
}

resource "ovh_cloud_project_user_s3_policy" "thanos_read_policy" {
  user_id = ovh_cloud_project_user.thanos_read_user.id
  policy = jsonencode({
    "Statement" : [{
      "Sid" : "ROContainer",
      "Effect" : "Allow",
      "Action" : ["s3:GetObject", "s3:ListBucket", "s3:ListMultipartUploadParts", "s3:ListBucketMultipartUploads"],
      "Resource" : ["arn:aws:s3:::${aws_s3_bucket.thanos_bucket.bucket}", "arn:aws:s3:::${aws_s3_bucket.thanos_bucket.bucket}/*"]
    }]
  })
}

