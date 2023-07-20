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
}

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

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed?ref=v4.0.2"

  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  enable_service_monitor = var.cert_manager_enable_service_monitor

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

  dependency_ids = {
    ingress_controller = module.ingress_controller.id
    cert-manager       = module.cert-manager.id
  }
}

module "authorization_with_keycloak" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git//oidc_bootstrap?ref=v1.1.1"

  cluster_name   = var.cluster_name
  base_domain    = module.scaleway.base_domain
  cluster_issuer = var.cluster_issuer
  user_map = {
    jdoe = {
      username   = "jdoe"
      email      = "john.doe@camptocamp.com"
      first_name = "John"
      last_name  = "Doe"
    }
  }
  dependency_ids = {
    keycloak = module.authentication_with_keycloak.id
  }
}


module "kube-prometheus-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack//kind?ref=v3.2.0"

  cluster_name     = var.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  base_domain      = module.scaleway.base_domain
  cluster_issuer   = var.cluster_issuer

  prometheus = {
    oidc = module.authorization_with_keycloak.oidc
  }
  alertmanager = {
    oidc = module.authorization_with_keycloak.oidc
  }
  grafana = {
    oidc = module.authorization_with_keycloak.oidc
  }

  dependency_ids = {
    ingress_controller      = module.ingress_controller.id
    cert-manager = module.cert-manager.id
    oidc         = module.authentication_with_keycloak.id
  }
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v1.1.0"

  base_domain              = module.scaleway.base_domain
  cluster_name             = var.cluster_name
  cluster_issuer           = var.cluster_issuer
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens

  oidc = {
    name         = "OIDC"
    issuer       = module.authorization_with_keycloak.oidc.issuer_url
    clientID     = module.authorization_with_keycloak.oidc.client_id
    clientSecret = module.authorization_with_keycloak.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }

  dependency_ids = {
    ingress_controller               = module.ingress_controller.id
    cert-manager          = module.cert-manager.id
    oidc                  = module.authorization_with_keycloak.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}

