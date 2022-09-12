provider "helm" {
  kubernetes {
    host                   = module.cluster.kube_admin_config.host
    token                  = module.cluster.kube_admin_config.token
    cluster_ca_certificate = module.cluster.kube_admin_config.cluster_ca_certificate
  }
}

provider "kubernetes" {
    host                   = module.cluster.kube_admin_config.host
    token                  = module.cluster.kube_admin_config.token
    cluster_ca_certificate = module.cluster.kube_admin_config.cluster_ca_certificate
}

provider "argocd" {
  server_addr                 = "127.0.0.1:8080"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace

  kubernetes {
    host                   = module.cluster.kube_admin_config.host
    token                  = module.cluster.kube_admin_config.token
    cluster_ca_certificate = module.cluster.kube_admin_config.cluster_ca_certificate
  }
}

