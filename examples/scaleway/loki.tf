data "scaleway_account_project" "devops_stack" {
  project_id = var.project_id
}

resource "scaleway_object_bucket" "loki" {
  name = "devops-stack-loki-logs"
  tags = {
    line     = "devops-stack"
    platform = "scw-devops-stack-example"
  }
}

resource "scaleway_iam_application" "loki" {
  name        = "devops-stack-example-loki"
  description = "Loki access to S3 buckets from Devops Stack example"
}

resource "scaleway_iam_policy" "loki" {
  name           = "devops-stack-example-loki"
  description    = "Loki access to S3 buckets from Devops Stack example"
  application_id = scaleway_iam_application.loki.id

  rule {
    project_ids = [data.scaleway_account_project.devops_stack.id]
    permission_set_names = [
      "ObjectStorageObjectsDelete",
      "ObjectStorageObjectsRead",
      "ObjectStorageObjectsWrite",
      "ObjectStorageBucketsRead",
    ]
  }
}

resource "scaleway_iam_api_key" "loki" {
  application_id     = scaleway_iam_application.loki.id
  description        = "Loki credentials for Devops Stack example"
  default_project_id = data.scaleway_account_project.devops_stack.id
}

locals {
  loki_common_settings = {
    extraEnv = [
      {
        name = "AWS_ACCESS_KEY_ID"
        valueFrom = {
          secretKeyRef = {
            name = kubernetes_secret.credentials_loki_s3.metadata.0.name
            key  = "AWS_ACCESS_KEY_ID"
          }
        }
      },
      {
        name = "AWS_SECRET_ACCESS_KEY"
        valueFrom = {
          secretKeyRef = {
            name = kubernetes_secret.credentials_loki_s3.metadata.0.name
            key  = "AWS_SECRET_ACCESS_KEY"
          }
        }
      },
    ]
  }
}

module "loki" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git?ref=v8.1.0"

  app_autosync = {}

  retention = "9000h"
  ingress = {
    hosts          = ["loki.apps.${var.cluster_name}.${var.base_domain}"]
    cluster_issuer = var.cluster_issuer
  }

  helm_values = [{
    loki-distributed = {
      loki = merge({
        structuredConfig = {
          auth_enabled = false
          compactor = {
            retention_delete_delay = "1h"
            retention_enabled      = false
          }
          ingester = {
            lifecycler = {
              ring = {
                replication_factor = 1
              }
            }
          }
        }
        schemaConfig = {
          configs = [
            {
              from         = "2023-04-28",
              store        = "boltdb-shipper"
              object_store = "s3"
              schema       = "v11"
              index = {
                prefix = "index_"
                period = "24h"
              }
            }
          ]
        }
        storageConfig = {
          aws = {
            bucketnames      = scaleway_object_bucket.loki.id
            endpoint         = scaleway_object_bucket.loki.endpoint
            s3forcepathstyle = true
            #region            = "fr-par"
            sse_encryption    = false
            signature_version = "v2"
          }
          boltdb_shipper = {
            shared_store = "s3"
            cache_ttl    = "24h"
          }
        }
      }, local.loki_common_settings)
      indexGateway  = local.loki_common_settings
      ingester      = merge({ replicas = 1 }, local.loki_common_settings)
      compactor     = local.loki_common_settings
      queryFrontend = local.loki_common_settings
      querier       = local.loki_common_settings
      distributor   = local.loki_common_settings
    }
    promtail = {
      updateStrategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxUnavailable = 3
        }
      }
      config = {
        clients = [
          {
            url = "http://loki-distributor:3100/loki/api/v1/push"
            #tenant_id = 1
          }
        ]
      }
    }
  }]
}

resource "kubernetes_secret" "credentials_loki_s3" {
  metadata {
    namespace = "loki-stack"
    name      = "credentials-loki-s3"
  }

  data = {
    AWS_ACCESS_KEY_ID     = scaleway_iam_api_key.loki.access_key
    AWS_SECRET_ACCESS_KEY = scaleway_iam_api_key.loki.secret_key
  }

}
