locals {
  base_domain                       = format("%s.nip.io", replace(module.cluster.ingress_ip_address, ".", "-"))
  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_username               = local.context.users.0.user.username
  kubernetes_password               = local.context.users.0.user.password
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
}

provider "helm" {
  kubernetes {
    insecure         = true
    host             = local.kubernetes_host
    username         = local.kubernetes_username
    password         = local.kubernetes_password
    load_config_file = false
  }
}

module "cluster" {
  source  = "camptocamp/k3s/docker"
  version = "0.3.2"

  cluster_name = var.cluster_name
  k3s_version  = var.k3s_version
  node_count   = var.node_count
}

resource "helm_release" "argocd" {
  name              = "argocd"
  chart             = "${path.module}/../../argocd/argocd"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    file("${path.module}/../../argocd/argocd/values.yaml")
  ]

  depends_on = [
    module.cluster,
  ]
}



resource "helm_release" "app_of_apps" {
  name              = "app-of-apps"
  chart             = "${path.module}/../../argocd/app-of-apps"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        cluster_name    = var.cluster_name,
        base_domain     = local.base_domain,
        repo_url        = var.repo_url,
        target_revision = var.target_revision,
        clientid        = "applications"
        clientsecret    = random_password.clientsecret.result
        admin_password  = random_password.admin_password.result
        cookie_secret   = random_password.cookie_secret.result
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    helm_release.argocd,
  ]
}

resource "random_password" "clientsecret" {
  length  = 16
  special = false
}

resource "random_password" "admin_password" {
  length  = 16
  special = false
}

resource "random_password" "cookie_secret" {
  length  = 16
  special = false
}

resource "random_password" "minioaccesskey" {
  length           = 128
  special          = true
  override_special = "_%@"
}

resource "random_password" "miniosecretkey" {
  length           = 128
  special          = true
  override_special = "_%@"
}

resource "vault_generic_secret" "minio" {
  path = "secret/minio"

  data_json = <<EOT
{
  "accessKey":   "${random_password.minioaccesskey.result}",
  "secretkey":   "${random_password.miniosecretkey.result}",
}
EOT
}

resource "vault_policy" "minio" {
  name = "minio"

  policy = <<EOT
path "secret/data/minio" {
  capabilities = ["read", "list"]
}
path "sys/renew/*" {
  capabilities = ["update"]
}
path "sys/mounts" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "minio" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "minio"
  bound_service_account_names      = ["minio", "secrets-store-csi-driver"]
  bound_service_account_namespaces = ["minio", "secrets-store-csi-driver"]
  token_ttl                        = 3600
  token_policies                   = ["default"]
}
