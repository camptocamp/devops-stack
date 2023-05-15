# Providers configuration

# These providers depend on the output of the respectives modules declared below.
# However, for clarity and easo of maintenance we grouped them all together in this section.

provider "kubernetes" {
  host                   = module.kind.parsed_kubeconfig.host
  client_certificate     = module.kind.parsed_kubeconfig.client_certificate
  client_key             = module.kind.parsed_kubeconfig.client_key
  cluster_ca_certificate = module.kind.parsed_kubeconfig.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.kind.parsed_kubeconfig.host
    client_certificate     = module.kind.parsed_kubeconfig.client_certificate
    client_key             = module.kind.parsed_kubeconfig.client_key
    cluster_ca_certificate = module.kind.parsed_kubeconfig.cluster_ca_certificate
  }
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

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = module.keycloak.admin_credentials.username
  password                 = module.keycloak.admin_credentials.password
  url                      = "https://keycloak.apps.${local.cluster_name}.${local.base_domain}"
  tls_insecure_skip_verify = true
  initial_login            = false
}

###

# Module declarations and configuration

module "kind" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cluster-kind.git?ref=v2.2.0"

  cluster_name       = local.cluster_name
  kubernetes_version = local.kubernetes_version
}

module "metallb" {
  source = "git::https://github.com/camptocamp/devops-stack-module-metallb.git?ref=v1.0.1"

  subnet = module.kind.kind_subnet
}

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v1.1.0"
}

module "traefik" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//kind?ref=v1.0.0"

  cluster_name = local.cluster_name

  # TODO fix: the base domain is defined later. Proposal: remove redirection from traefik module and add it in dependent modules.
  # For now random value is passed to base_domain. Redirections will not work before fix.
  base_domain = "placeholder.com"

  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed?ref=v2.0.0"

  # TODO remove useless base_domain and cluster_name variables from "self-signed" module.
  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "keycloak" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak?ref=v1.1.0"

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
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak//oidc_bootstrap?ref=v1.1.0"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  cluster_issuer = local.cluster_issuer

  dependency_ids = {
    keycloak = module.keycloak.id
  }
}

module "minio" {
  source = "git::https://github.com/camptocamp/devops-stack-module-minio?ref=v1.1.0"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  enable_service_monitor = false

  config_minio = local.minio_config

  oidc = module.oidc.oidc

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
  }
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack//kind?ref=v2.0.2"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
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

module "thanos" {
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos//kind?ref=v1.0.0"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  metrics_storage = {
    bucket_name       = local.minio_config.buckets.1.name
    endpoint          = module.minio.endpoint
    access_key        = local.minio_config.users.1.accessKey
    secret_access_key = local.minio_config.users.1.secretKey
  }

  thanos = {
    oidc = module.oidc.oidc
  }

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    minio        = module.minio.id
    oidc         = module.oidc.id
  }
}

module "kube-prometheus-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack//kind?ref=v2.3.0"

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
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v1.1.0"

  base_domain              = local.base_domain
  cluster_name             = local.cluster_name
  cluster_issuer           = local.cluster_issuer
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
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
    traefik               = module.traefik.id
    cert-manager          = module.cert-manager.id
    oidc                  = module.oidc.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}

module "metrics_server" {
  source = "git::https://github.com/camptocamp/devops-stack-module-application.git?ref=v1.2.2"

  name             = "metrics-server"
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  source_repo            = "https://github.com/kubernetes-sigs/metrics-server.git"
  source_repo_path       = "charts/metrics-server"
  source_target_revision = "metrics-server-helm-chart-3.8.3"
  destination_namespace  = "kube-system"

  helm_values = [{
    args = [
      "--kubelet-insecure-tls" # Ignore self-signed certificates of the KinD cluster
    ]
  }]

  dependency_ids = {
    argocd = module.argocd.id
  }
}
