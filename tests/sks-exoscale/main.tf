module "cluster" {
  source = "../../modules/sks/exoscale"

  cluster_name = var.cluster_name
  zone         = var.zone

  kubernetes_version = "1.22.5"

  nodepools = {
    "router-${var.cluster_name}" = {
      size          = 2
      instance_type = "standard.large"
    }

    "compute-${var.cluster_name}" = {
      size          = 2
      instance_type = "standard.large"
    }
  }
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
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//modules/sks"

  cluster_name     = var.cluster_name
  argocd_namespace = module.cluster.argocd_namespace
  base_domain      = module.cluster.base_domain

  zone                      = var.zone
  router_pool_id            = module.cluster.router_pool_id
  cluster_security_group_id = module.cluster.cluster_security_group_id
}
