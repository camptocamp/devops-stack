module "cluster" {
  source = "../../modules/k3s/docker"

  cluster_name = var.cluster_name

  repo_url        = "https://github.com/raphink/devops-stack.git"
  target_revision = "argo_modules"
  wait_for_app_of_apps = false
}

module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//terraform"

  cluster_name   = var.cluster_name
  argocd         = {
    server     = module.cluster.argocd_server
    auth_token = module.cluster.argocd_auth_token
    namespace  = module.cluster.argocd_namespace
  }
  kubernetes     = module.cluster.kubernetes
  base_domain    = module.cluster.base_domain
}

#module "oidc" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git//terraform"
#}

#module "oidc" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-cognito.git//terraform"
#}

module "monitoring" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//terraform"

  cluster_name   = var.cluster_name
  oidc           = module.cluster.oidc
  argocd         = {
    server     = module.cluster.argocd_server
    auth_token = module.cluster.argocd_auth_token
    namespace  = module.cluster.argocd_namespace
  }
  kubernetes     = module.cluster.kubernetes
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
