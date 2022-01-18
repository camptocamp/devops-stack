locals {
  base_domain                       = coalesce(var.base_domain, format("%s.nip.io", replace(module.cluster.ingress_ip_address, ".", "-")))
  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubeconfig                        = module.cluster.kubeconfig
}

provider "helm" {
  kubernetes {
    host               = local.kubernetes_host
    client_certificate = local.kubernetes_client_certificate
    client_key         = local.kubernetes_client_key
    insecure           = true
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

module "argocd" {
  source = "../../argocd-helm"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  extra_app_projects      = var.extra_app_projects
  extra_application_sets  = var.extra_application_sets
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  argocd_server_secretkey = var.argocd_server_secretkey
  cluster_issuer          = "ca-issuer"
  wait_for_app_of_apps    = var.wait_for_app_of_apps

  repositories = var.repositories

  app_of_apps_values_overrides = [
    templatefile("${path.module}/../values.tmpl.yaml",
      {
        base_domain      = local.base_domain
        cluster_name     = var.cluster_name
        #root_cert        = base64encode(tls_self_signed_cert.root.cert_pem)
        #root_key         = base64encode(tls_private_key.root.private_key_pem)
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
  ]
}
