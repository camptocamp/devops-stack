module "cluster" {
  source = "../../modules/k3s/docker"

  cluster_name = var.cluster_name

  repo_url        = "https://github.com/raphink/devops-stack.git"
  target_revision = "argo_modules"
  wait_for_app_of_apps = false
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
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//terraform"

  cluster_name   = var.cluster_name
  argocd         = {
    namespace = module.cluster.argocd_namespace
  }
  base_domain    = module.cluster.base_domain
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git//terraform"

  cluster_name   = var.cluster_name
  oidc           = module.cluster.oidc
  argocd         = {
    namespace = module.cluster.argocd_namespace
    domain    = module.cluster.argocd_domain
  }
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"
}

#module "oidc" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-cognito.git//terraform"
#}

module "monitoring" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//terraform"

  cluster_name   = var.cluster_name
  oidc           = module.cluster.oidc
  argocd         = {
    namespace = module.cluster.argocd_namespace
  }
  base_domain    = module.cluster.base_domain
  cluster_issuer = "ca-issuer"
  metrics_archives = {}
}

#module "myownapp" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-applicationset.git"
#
#  cluster_name   = module.cluster.cluster_name
#  oidc           = module.cluster.oidc
#  argocd         = {
#    server     = module.cluster.argocd_server
#    auth_token = module.cluster.argocd_auth_token
#  }
#  base_domain    = module.cluster.base_domain
#  cluster_issuer = module.cluster.cluster_issuer
#
#  argocd_url = "https://github.com/camptocamp/myapp.git"
#}
