# Cluster

locals {
  cluster_name     = "gh-v1-cluster"
  cluster_issuer   = "ca-issuer"
  argocd_namespace = "argocd"
}

module "kind" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kind.git?ref=v1.0.0"

  cluster_name = local.cluster_name
  # base_domain  = "127-0-0-1.nip.io" # I need this line in Windows to access my pods in WSL 2

  # Need to use < v1.25 because of Keycloak trying to deploy a PodDisruptionBudget
  # https://kubernetes.io/docs/reference/using-api/deprecation-guide/#poddisruptionbudget-v125 
  kubernetes_version = "v1.24.7"
}

#######

# Providers

provider "kubernetes" {
  host                   = module.kind.kubernetes_host
  client_certificate     = module.kind.kubernetes_client_certificate
  client_key             = module.kind.kubernetes_client_key
  cluster_ca_certificate = module.kind.kubernetes_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host               = module.kind.kubernetes_host
    client_certificate = module.kind.kubernetes_client_certificate
    client_key         = module.kind.kubernetes_client_key
    insecure           = true # This is needed because the Certificate Authority is self-signed.
  }
}

provider "argocd" {
  server_addr                 = "127.0.0.1:8080"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = local.argocd_namespace

  kubernetes {
    host                   = module.kind.kubernetes_host
    client_certificate     = module.kind.kubernetes_client_certificate
    client_key             = module.kind.kubernetes_client_key
    cluster_ca_certificate = module.kind.kubernetes_cluster_ca_certificate
  }
}

#######

# Bootstrap Argo CD

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v1.0.0-alpha.1"

  cluster_name = module.kind.cluster_name
  base_domain  = module.kind.base_domain

  # An empty cluster issuer is the only way I got the bootstrap Argo CD to be deployed.
  # The `ca-issuer` is only available after we deployed `cert-manager`.
  cluster_issuer = ""

  depends_on = [module.kind]
}

#######

# Cluster apps

module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//nodeport?ref=v1.0.0-alpha.4"

  cluster_name     = module.kind.cluster_name
  base_domain      = module.kind.base_domain
  argocd_namespace = local.argocd_namespace

  # We cannot have multiple Traefik replicas binding to the same ports while both are deployed on 
  # the same KinD container in Docker, which is our case as we only deploy the control-plane node.
  # TODO Consider adding these modifications to the module directly.
  helm_values = [{
    traefik = {
      deployment = {
        replicas = 1
      }
      nodeSelector = {
        "ingress-ready" = "true"
      }
      tolerations = [
        {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Equal"
          effect   = "NoSchedule"
        },
        {
          key      = "node-role.kubernetes.io/master"
          operator = "Equal"
          effect   = "NoSchedule"
        }
      ]
    }
  }]

  depends_on = [module.argocd_bootstrap]
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed?ref=v1.0.0-alpha.2"

  cluster_name     = module.kind.cluster_name
  base_domain      = module.kind.base_domain
  argocd_namespace = local.argocd_namespace

  depends_on = [module.argocd_bootstrap]
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak?ref=v1.0.0-alpha.1"

  cluster_name   = module.kind.cluster_name
  base_domain    = module.kind.base_domain
  cluster_issuer = local.cluster_issuer

  argocd = { # TODO Simplify this variable in the Keycloak module because we only need the namespace and not the domain
    namespace = local.argocd_namespace
    domain    = module.argocd_bootstrap.argocd_domain
  }

  depends_on = [module.ingress, module.cert-manager]
}

module "minio" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-minio?ref=v1.0.0"
  source = "git::https://github.com/camptocamp/devops-stack-module-minio?ref=module_revamping"
  # TODO Remove temporary source after we merged

  cluster_name     = module.kind.cluster_name
  base_domain      = module.kind.base_domain
  argocd_namespace = local.argocd_namespace
  target_revision  = "module_revamping" # TODO delete after we merged

  minio_buckets = [
    "thanos",
    "loki",
  ]

  # Deactivate the ServiceMonitor because we need to deploy MinIO before the monitoring stack.
  helm_values = [{
    minio = {
      metrics = {
        serviceMonitor = {
          enabled = false
        }
      }
    }
  }]

  depends_on = [module.ingress, module.cert-manager]
}

module "thanos" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-thanos//kind?ref=v1.0.0"
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos//kind?ref=bucket_credentials_v2"

  cluster_name     = module.kind.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.kind.base_domain
  cluster_issuer   = local.cluster_issuer

  metrics_storage = {
    bucket_name       = "thanos"
    endpoint          = module.minio.endpoint
    access_key        = "readwrite_user" # Name given to the read-write user created by the module MinIO.
    secret_access_key = module.minio.readwrite_secret_key
  }

  thanos = {
    oidc = module.oidc.oidc
  }

  depends_on = [module.oidc]
}

module "prometheus-stack" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack//kind?ref=v1.0.0"
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack//kind?ref=variable_revamp"

  cluster_name     = module.kind.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.kind.base_domain
  cluster_issuer   = local.cluster_issuer

  metrics_storage = {
    bucket_name       = "thanos"
    endpoint          = module.minio.endpoint
    access_key        = "readwrite_user" # Name given to the read-write user created by the module MinIO.
    secret_access_key = module.minio.readwrite_secret_key
  }

  prometheus = {
    oidc = module.oidc.oidc
  }
  alertmanager = {
    oidc = module.oidc.oidc
  }
  grafana = {
    # enable = false # Optional
    additional_data_sources = true
  }

  depends_on = [module.oidc]
}

module "loki-stack" {
  # source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack//kind?ref=v1.0.0"
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack//kind?ref=bucket_credentials"

  cluster_name     = module.kind.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.kind.base_domain

  logs_storage = {
    bucket_name       = "loki"
    endpoint          = module.minio.endpoint
    access_key        = "readwrite_user" # Name given to the read-write user created by the module MinIO.
    secret_access_key = module.minio.readwrite_secret_key
  }

  depends_on = [module.prometheus-stack]
}

module "grafana" {
  source = "git::https://github.com/camptocamp/devops-stack-module-grafana.git?ref=v1.0.0-alpha.1"

  cluster_name     = module.kind.cluster_name
  argocd_namespace = local.argocd_namespace
  base_domain      = module.kind.base_domain
  cluster_issuer   = local.cluster_issuer

  grafana = {
    oidc = module.oidc.oidc
    # We need to explicitly tell Grafana to ignore the self-signed certificate on the OIDC provider.
    generic_oauth_extra_args = {
      tls_skip_verify_insecure = true
    }
  }

  depends_on = [module.prometheus-stack, module.loki-stack]
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v1.0.0-alpha.1"

  cluster_name   = module.kind.cluster_name
  base_domain    = module.kind.base_domain
  cluster_issuer = local.cluster_issuer

  bootstrap_values = module.argocd_bootstrap.bootstrap_values

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
    requestedScopes = [
      "openid", "profile", "email"
    ]
  }

  # TODO Get Argo CD to work with OIDC from Keycloak
  helm_values = [{
    argo-cd = {
      server = {
        config = {
          "oidc.tls.insecure.skip.verify" = true
        }
      }
    }
  }]

  argocd = {
    namespace                = local.argocd_namespace
    server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
    accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
    server_admin_password    = module.argocd_bootstrap.argocd_server_admin_password
    domain                   = module.argocd_bootstrap.argocd_domain
    admin_enabled            = true # Enable admin user while we cannot use OIDC
  }

  depends_on = [module.cert-manager, module.prometheus-stack, module.grafana]
}

# module "helloworld_apps" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git?ref=v1.1.0"

#   depends_on = [module.argocd]

#   name                   = "helloworld-apps"
#   argocd_namespace       = local.argocd_namespace
#   project_dest_namespace = "*"
#   project_source_repo    = "https://github.com/camptocamp/devops-stack-helloworld-templates.git"

#   generators = [
#     {
#       git = {
#         repoURL  = "https://github.com/camptocamp/devops-stack-helloworld-templates.git"
#         revision = "main"

#         directories = [
#           {
#             path = "apps/*"
#           }
#         ]
#       }
#     }
#   ]
#   template = {
#     metadata = {
#       name = "{{path.basename}}"
#     }

#     spec = {
#       project = "helloworld-apps"

#       source = {
#         repoURL        = "https://github.com/camptocamp/devops-stack-helloworld-templates.git"
#         targetRevision = "main"
#         path           = "{{path}}"

#         helm = {
#           valueFiles = []
#           # The following value defines this global variables that will be available to all apps in apps/*
#           # These are needed to generate the ingresses containing the name and base domain of the cluster.
#           values = <<-EOT
#             cluster:
#               name: "${module.kind.cluster_name}"
#               domain: "${module.kind.base_domain}"
#             apps:
#               traefik_dashboard: false
#               grafana: true
#               prometheus: true
#               thanos: true
#               alertmanager: true
#           EOT
#         }
#       }

#       destination = {
#         name      = "in-cluster"
#         namespace = "{{path.basename}}"
#       }

#       syncPolicy = {
#         automated = {
#           allowEmpty = false
#           selfHeal   = true
#           prune      = true
#         }
#         syncOptions = [
#           "CreateNamespace=true"
#         ]
#       }
#     }
#   }
# }

########
