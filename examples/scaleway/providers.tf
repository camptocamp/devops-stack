provider "scaleway" {
  region = "fr-par"
}

provider "helm" {
  kubernetes {
    host                   = module.scaleway.kubeconfig.0.host
    token                  = module.scaleway.kubeconfig.0.token
    cluster_ca_certificate = base64decode(module.scaleway.kubeconfig.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.scaleway.kubeconfig.0.host
  token                  = module.scaleway.kubeconfig.0.token
  cluster_ca_certificate = base64decode(module.scaleway.kubeconfig.0.cluster_ca_certificate)
}


provider "argocd" {
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true

  kubernetes {
    host                   = module.scaleway.kubeconfig.0.host
    token                  = module.scaleway.kubeconfig.0.token
    cluster_ca_certificate = base64decode(module.scaleway.kubeconfig.0.cluster_ca_certificate)
  }
}

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = module.authentication_with_keycloak.admin_credentials.username
  password                 = module.authentication_with_keycloak.admin_credentials.password
  url                      = "https://keycloak.apps.${var.cluster_name}.${var.base_domain}"
  initial_login            = false # Do no try to setup the provider before Keycloak is provisioned.
  tls_insecure_skip_verify = true  # Since we are in a testing environment, do not verify the authenticity of SSL certificates.
}
