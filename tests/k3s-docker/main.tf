# bootstrap
module "cluster" {
  source = "../../modules/k3s/docker"

  cluster_name = var.cluster_name

  repo_url        = "https://github.com/raphink/devops-stack.git"
  target_revision = "argo_modules"
}

provider "argocd" {
  server_addr = "127.0.0.1:8080"
  auth_token  = module.cluster.argocd_auth_token
  insecure = true
  plain_text = true
  port_forward = true
  port_forward_with_namespace = module.cluster.argocd_namespace

  kubernetes {
    host                   = module.cluster.kubernetes.host
    client_certificate     = module.cluster.kubernetes.client_certificate
    client_key             = module.cluster.kubernetes.client_key
    cluster_ca_certificate = module.cluster.kubernetes.cluster_ca_certificate
  }
}

module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//modules"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git//modules"

  cluster_name   = var.cluster_name
  argocd         = {
    namespace = module.cluster.argocd_namespace
    domain    = module.cluster.argocd_domain
  }
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"

  depends_on = [ module.ingress ]
}

#module "oidc" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-cognito.git//modules"
#}

module "monitoring" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//modules"

  cluster_name     = var.cluster_name
  oidc             = module.oidc.oidc
  argocd_namespace = module.cluster.argocd_namespace
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"
  metrics_archives = {}

  depends_on = [ module.oidc ]
}

#module "metrics-archives" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-thanos.git//modules/k3s"
#
#  cluster_name     = var.cluster_name
#  argocd_namespace = module.cluster.argocd_namespace
#  base_domain      = module.cluster.base_domain
#  cluster_issuer   = "ca-issuer"
#
#  minio = {
#    access_key = module.storage.access_key
#    secret_key = module.storage.secret_key
#  }
#
#  depends_on = [ module.monitoring, module.loki-stack ]
#}

module "storage" {
  source = "git::https://github.com/camptocamp/devops-stack-module-minio.git//modules"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain
  cluster_issuer   = "ca-issuer"

  minio = {
    buckets = {
      loki = {}
      thanos = {}
    }
  }

  depends_on = [ module.monitoring ]
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//modules/k3s"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  minio = {
    access_key = module.storage.access_key
    secret_key = module.storage.secret_key
  }

  depends_on = [ module.monitoring, module.storage ]
}


module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//modules/self-signed"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  depends_on = [ module.monitoring ]
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//modules"

  cluster_name   = var.cluster_name
  oidc           = module.oidc.oidc
  argocd         = {
    namespace = module.cluster.argocd_namespace
    server_secretkey = module.cluster.argocd_server_secretkey
    accounts_pipeline_tokens = module.cluster.argocd_accounts_pipeline_tokens
    server_admin_password = module.cluster.argocd_server_admin_password
    domain = module.cluster.argocd_domain
    admin_enabled = true
  }
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"

  depends_on = [ module.cert-manager ]
}

#module "myownapp" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git//modules"
#
#  cluster_name   = module.cluster.cluster_name
#  oidc           = module.oidc.oidc
#  argocd         = {
#    server     = module.cluster.argocd_server
#    auth_token = module.cluster.argocd_auth_token
#  }
#  base_domain    = module.cluster.base_domain
#  cluster_issuer = module.cluster.cluster_issuer
#
#  argocd_url = "https://github.com/camptocamp/myapp.git"
#}
