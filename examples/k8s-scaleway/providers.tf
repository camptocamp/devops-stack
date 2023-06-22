provider "helm" {
  kubernetes {
    host                   = module.scaleway.kubeconfig.host
    token                  = module.scaleway.kubeconfig.token
    cluster_ca_certificate = module.scaleway.kubeconfig.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = module.scaleway.kubeconfig.host
  token                  = module.scaleway.kubeconfig.token
  cluster_ca_certificate = module.scaleway.kubeconfig.cluster_ca_certificate
}

provider "argocd" {
  server_addr                 = "127.0.0.1:8080"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace

  kubernetes {
    host                   = module.scaleway.kubeconfig.host
    token                  = module.scaleway.kubeconfig.token
    cluster_ca_certificate = module.scaleway.kubeconfig.cluster_ca_certificate
  }
}

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = module.authentication_with_keycloak.admin_credentials.username
  password                 = module.authentication_with_keycloak.admin_credentials.password
  url                      = "https://keycloak.apps.${var.cluster_name}.${format("%s.nip.io", replace(module.scaleway.lb_ip_address, ".", "-"))}"
  initial_login            = false # Do no try to setup the provider before Keycloak is provisioned.
  tls_insecure_skip_verify = true  # Since we are in a testing environment, do not verify the authenticity of SSL certificates.
}
