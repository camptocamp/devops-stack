locals {
  env                    = "dev"
  cluster_name           = local.env
  cluster_issuer         = "letsencrypt-stagging"
  base_domain            = format("%s.%s", local.env, "qalita.io")
  enable_service_monitor = false

  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)

  domaine_zone_name = module.cluster.domaine_zone_name

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

module "cluster" {

  source = "git::https://github.com/qalita-io/devops-stack.git//modules/ovh?ref=ovh"

  vlan_name           = format("%s-net", local.cluster_name)
  vlan_subnet_start   = "192.168.168.100"
  vlan_subnet_end     = "192.168.168.200"
  vlan_subnet_network = "192.168.168.0/24"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  cluster_region = "GRA9"

  flavor_name   = "c2-7"
  desired_nodes = 3
  max_nodes     = 3
  min_nodes     = 3

}

module "argocd_bootstrap" {
  source     = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v2.1.0"
}

module "traefik" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//kind?ref=v1.2.3"

  cluster_name           = local.cluster_name
  base_domain            = local.base_domain
  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  enable_service_monitor = local.enable_service_monitor

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
  depends_on = [module.traefik.id]
}

# Add a record to a sub-domain
resource "ovh_domain_zone_record" "wildcard_record" {
  zone       = local.domaine_zone_name
  subdomain  = "*"
  fieldtype  = "A"
  ttl        = 3600
  target     = data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip
  depends_on = [module.traefik.id]
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager?ref=v4.0.3"

  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  enable_service_monitor = local.enable_service_monitor

  helm_values = [{
    cert-manager = {
      clusterIssuers = {
        letsencrypt = {
          enabled = true
        }
        acme = {
          solvers = [
            {
              http01 = {
                ingress = {}
              }
            }
          ]
        }
      }
    }
  }]

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "keycloak" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak?ref=v1.1.1"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
  }
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak//oidc_bootstrap?ref=v1.1.1"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  cluster_issuer = local.cluster_issuer

  dependency_ids = {
    keycloak = module.keycloak.id
  }
}

module "minio" {
  source = "git::https://github.com/camptocamp/devops-stack-module-minio?ref=v1.1.2"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  enable_service_monitor = local.enable_service_monitor
  config_minio           = local.minio_config
  oidc                   = module.oidc.oidc

  helm_values = [{
    minio = {
      persistence = {
        size = "50Gi"
      }
    }
  }]

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
  }
}

resource "random_password" "loki_secretkey" {
  length  = 32
  special = false
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack//kind?ref=v3.0.0"

  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  distributed_mode = true

  logs_storage = {
    bucket_name = local.minio_config.buckets.0.name
    endpoint    = module.minio.endpoint
    access_key  = local.minio_config.users.0.accessKey
    secret_key  = local.minio_config.users.0.secretKey
  }

  dependency_ids = {
    minio = module.minio.id
  }
}

resource "random_password" "thanos_secretkey" {
  length  = 32
  special = false
}

module "thanos" {
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos//kind?ref=v1.1.0"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  metrics_storage = {
    bucket_name = local.minio_config.buckets.1.name
    endpoint    = module.minio.endpoint
    access_key  = local.minio_config.users.1.accessKey
    secret_key  = local.minio_config.users.1.secretKey
  }

  thanos = {
    oidc = module.oidc.oidc
  }

  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    minio        = module.minio.id
    keycloak     = module.keycloak.id
    oidc         = module.oidc.id
  }
}

module "kube-prometheus-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack//kind?ref=v3.2.0"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  metrics_storage = {
    bucket     = local.minio_config.buckets.1.name
    endpoint   = module.minio.endpoint
    access_key = local.minio_config.users.1.accessKey
    secret_key = local.minio_config.users.1.secretKey
  }

  prometheus = {
    oidc = module.oidc.oidc
  }
  alertmanager = {
    oidc = module.oidc.oidc
  }
  grafana = {
    oidc = module.oidc.oidc
  }

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    minio        = module.minio.id
    oidc         = module.oidc.id
  }
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v2.1.0"

  base_domain              = local.base_domain
  cluster_name             = local.cluster_name
  cluster_issuer           = local.cluster_issuer
  admin_enabled            = "true"
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  namespace                = module.argocd_bootstrap.argocd_namespace
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens

  oidc = {
    name         = "OIDC"
    issuer       = module.oidc.oidc.issuer_url
    clientID     = module.oidc.oidc.client_id
    clientSecret = module.oidc.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }

  dependency_ids = {
    argocd                = module.argocd_bootstrap.id
    traefik               = module.traefik.id
    cert-manager          = module.cert-manager.id
    oidc                  = module.oidc.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}
