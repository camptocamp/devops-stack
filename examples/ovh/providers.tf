provider "helm" {
  kubernetes {
    host                   = module.cluster.kube_admin_config.kubernetes_host
    client_key             = module.cluster.kube_admin_config.kubernetes_client_key
    client_certificate     = module.cluster.kube_admin_config.kubernetes_client_certificate
    cluster_ca_certificate = module.cluster.kube_admin_config.kubernetes_cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = module.cluster.kube_admin_config.kubernetes_host
  client_key             = module.cluster.kube_admin_config.kubernetes_client_key
  client_certificate     = module.cluster.kube_admin_config.kubernetes_client_certificate
  cluster_ca_certificate = module.cluster.kube_admin_config.kubernetes_cluster_ca_certificate
}

provider "argocd" {
  server_addr                 = "127.0.0.1:8080"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace

  kubernetes {
    host                   = module.cluster.kube_admin_config.kubernetes_host
    client_key             = module.cluster.kube_admin_config.kubernetes_client_key
    client_certificate     = module.cluster.kube_admin_config.kubernetes_client_certificate
    cluster_ca_certificate = module.cluster.kube_admin_config.kubernetes_cluster_ca_certificate
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

provider "ovh" {}
