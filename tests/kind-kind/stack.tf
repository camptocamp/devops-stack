# -------
# BM review dependency_ids of all modules
# TODO add repo_url / chart_path variables to all modules with argocd apps: helps with chart dev.

locals {
  cluster_name   = "kind-cluster"
  cluster_issuer = "ca-issuer"
  minio_config = {
    users = [
      {
        accessKey = "loki"
        secretKey = random_password.loki_secretkey.result
        policy    = "readwrite"
      },
      {
        accessKey = "thanos"
        secretKey = random_password.thanos_secretkey.result
        policy    = "readwrite"
      }
    ]
    buckets = [
      {
        name = "loki"
      },
      {
        name = "thanos"
      }
    ]
  }
}

resource "random_password" "loki_secretkey" {
  length  = 48
  special = false
}

resource "random_password" "thanos_secretkey" {
  length  = 48
  special = false
}

module "kind" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cluster-kind.git?ref=v2.1.0"

  cluster_name       = local.cluster_name
  kubernetes_version = "v1.24.7"
}

provider "kubernetes" {
  host               = module.kind.parsed_kubeconfig.host
  client_certificate = module.kind.parsed_kubeconfig.client_certificate
  client_key         = module.kind.parsed_kubeconfig.client_key
  insecure           = true
}

provider "helm" {
  kubernetes {
    host               = module.kind.parsed_kubeconfig.host
    client_certificate = module.kind.parsed_kubeconfig.client_certificate
    client_key         = module.kind.parsed_kubeconfig.client_key
    insecure           = true
  }
}

module "metallb" {
  source = "git::https://github.com/camptocamp/devops-stack-module-metallb.git?ref=v1.0.0-alpha.1"

  subnet = module.kind.kind_subnet
}

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v1.0.0-alpha.6"
}

provider "argocd" {
  server_addr                 = "127.0.0.1:8080"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace
  kubernetes {
    host                   = module.kind.parsed_kubeconfig.host
    client_certificate     = module.kind.parsed_kubeconfig.client_certificate
    client_key             = module.kind.parsed_kubeconfig.client_key
    cluster_ca_certificate = module.kind.parsed_kubeconfig.cluster_ca_certificate
  }
}

# TODO restore nodeport submodule and create temporary new submodule for kind.
module "ingress" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//kind?ref=v1.0.0-alpha.9"
  target_revision = "v1.0.0-alpha.9"

  cluster_name = local.cluster_name

  # TODO fix: the base domain is defined later. Proposal: remove redirection from traefik module and add it in dependent modules.
  # For now random value is passed to base_domain. Redirections will not work before fix.
  base_domain = "something.com"

  argocd_namespace = module.argocd_bootstrap.argocd_namespace
}

# TODO upgrade cet-manager module
module "cert-manager" {
  # TODO remove useless base_domain and cluster_name variables from "self-signed" module.
  source          = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed?ref=v1.0.0-alpha.3"
  target_revision = "v1.0.0-alpha.3"

  cluster_name     = local.cluster_name
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
}

module "minio" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-minio?ref=v1.0.0"
  target_revision = "v1.0.0"

  cluster_name     = local.cluster_name
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  config_minio = local.minio_config

  dependency_ids = {
    traefik      = module.ingress.id
    cert-manager = module.cert-manager.id
  }
}

module "loki-stack" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-loki-stack//kind?ref=v1.0.0-alpha.11"
  target_revision = "v1.0.0-alpha.11"

  cluster_name     = local.cluster_name
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  distributed_mode = true

  logs_storage = {
    bucket_name       = local.minio_config.buckets.0.name
    endpoint          = module.minio.endpoint
    access_key        = local.minio_config.users.0.accessKey
    secret_access_key = local.minio_config.users.0.secretKey
  }

  dependency_ids = {
    minio = module.minio.id
  }
}

module "oidc" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-keycloak?ref=v1.0.0"
  target_revision = "v1.0.0"

  cluster_name     = local.cluster_name
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  dependency_ids = {
    traefik      = module.ingress.id
    cert-manager = module.cert-manager.id
  }
}

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = module.oidc.admin_credentials.username
  password                 = module.oidc.admin_credentials.password
  url                      = "https://keycloak.apps.${local.cluster_name}.${format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))}"
  tls_insecure_skip_verify = true
}

module "oidc_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak//oidc_bootstrap?ref=v1.0.0"

  cluster_name   = local.cluster_name
  base_domain    = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  cluster_issuer = local.cluster_issuer

  dependency_ids = {
    oidc = module.oidc.id
  }
}

# TODO upgrade thanos module
module "thanos" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-thanos//kind?ref=v1.0.0-alpha.6"
  target_revision = "v1.0.0-alpha.6"


  cluster_name     = local.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  cluster_issuer   = local.cluster_issuer

  metrics_storage = {
    bucket_name       = local.minio_config.buckets.1.name
    endpoint          = module.minio.endpoint
    access_key        = local.minio_config.users.1.accessKey
    secret_access_key = local.minio_config.users.1.secretKey
  }

  thanos = {
    oidc = module.oidc_bootstrap.oidc
  }

  dependency_ids = {
    minio    = module.minio.id
    keycloak = module.oidc.id
  }
}

module "prometheus-stack" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//kind?ref=v1.0.0-alpha.7"
  target_revision = "v1.0.0-alpha.7"

  cluster_name     = local.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  cluster_issuer   = local.cluster_issuer

  metrics_storage = {
    bucket     = local.minio_config.buckets.1.name
    endpoint   = module.minio.service
    access_key = local.minio_config.users.1.accessKey
    secret_key = local.minio_config.users.1.secretKey
  }

  # TODO conditional oidc activation for all 3 components.
  prometheus = {
    oidc = module.oidc_bootstrap.oidc
  }
  alertmanager = {
    oidc = module.oidc_bootstrap.oidc
  }
  grafana = {
    enabled                 = true
    oidc                    = module.oidc_bootstrap.oidc
    additional_data_sources = true
  }

  # Grafana server can't validate Keycloak's certificate. Following is a temporary workaround.
  # TODO fix this. Maybe a way to disable cert validation. If there is no way, add this config conditionally to module.
  helm_values = [{
    kube-prometheus-stack = {
      grafana = {
        extraSecretMounts = [
          {
            name       = "ca-certificate"
            secretName = "grafana-tls"
            mountPath  = "/etc/ssl/certs/ca.crt"
            readOnly   = true
            subPath    = "ca.crt"
          },
        ]
      }
    }
  }]

  dependency_ids = {
    keycloak     = module.oidc.id
    loki-stack   = module.loki-stack.id
    cert-manager = module.cert-manager.id
  }
}

module "argocd" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v1.0.0-alpha.6"
  target_revision = "v1.0.0-alpha.6"

  base_domain              = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  cluster_name             = local.cluster_name
  cluster_issuer           = local.cluster_issuer
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens

  oidc = {
    name         = "OIDC"
    issuer       = module.oidc_bootstrap.oidc.issuer_url
    clientID     = module.oidc_bootstrap.oidc.client_id
    clientSecret = module.oidc_bootstrap.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }

  helm_values = [{
    argo-cd = {
      configs = {
        rbac = {
          "scopes"     = "[groups]"
          "policy.csv" = <<-EOT
            g, pipeline, role:admin
            g, devops-stack-admins, role:admin
          EOT
        }
      }
    }
  }]

  dependency_ids = {
    oidc                  = module.oidc_bootstrap.id
    kube-prometheus-stack = module.prometheus-stack.id
  }
}

# module "backstage" {
#   source = "../../../../camptocamp/devops-stack-modules/devops-stack-module-backstage"

#   ingress = {
#     host           = "backstage.apps.${local.cluster_name}.${format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))}"
#     cluster_issuer = local.cluster_issuer
#   }
# }
