# ###########################
# INFRA + K8s PHASE
# ###########################
module "scaleway" {
  source = "git@github.com:camptocamp/devops-stack-module-cluster-scaleway.git"

  cluster_name        = var.cluster_name
  cluster_description = var.cluster_description
  cluster_tags        = var.cluster_tags
  kubernetes_version  = var.kubernetes_version
  lb_name             = var.lb_name
  lb_type             = var.lb_type
  zone                = var.zone
  node_pools          = var.node_pools
}

# ###########################
# BOOTSPRAP APPLICATION PHASE
# ###########################

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v2.0.0"

  depends_on = [module.scaleway]
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed?ref=v4.0.2"

  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  enable_service_monitor = var.cert_manager_enable_service_monitor

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

# need 
module "ingress_controller" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git?ref=v1.2.3"

  cluster_name           = var.cluster_name
  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  base_domain            = module.scaleway.base_domain
  enable_service_monitor = var.ingress_enable_service_monitor

  helm_values = [{
    traefik = {
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/scw-loadbalancer-id" = module.scaleway.lb_id
        }
      }
    }
  }]

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}


module "authentication_with_keycloak" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git?ref=v1.1.1"

  cluster_name     = var.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  base_domain      = module.scaleway.base_domain
  cluster_issuer   = var.cluster_issuer

  depends_on = [module.scaleway, module.argocd_bootstrap]
}

#module "authorization_with_keycloak" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git//oidc_bootstrap?ref=v1.1.1"
#
#  cluster_name     = var.cluster_name
#  base_domain = module.scaleway.base_domain
#
#  dependency_ids = {
#    keycloak = module.authentication_with_keycloak.id
#  }
#}


#module "prometheus-stack" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git?ref=v3.2.0"
#
#  cluster_name     = var.cluster_name
#  argocd_namespace = module.argocd_bootstrap.argocd_namespace
#  base_domain      = module.scaleway.base_domain
#  cluster_issuer   = var.cluster_issuer
#
#  prometheus = {
#    oidc = module.authentication_with_keycloak.oidc
#  }
#  alertmanager = {
#    oidc = module.authentication_with_keycloak.oidc
#  }
#  #  grafana = {
#  #    # enable = false # Optional
#  #    additional_data_sources = true
#  #  }
#
#  depends_on = [module.argocd_bootstrap]
#}
