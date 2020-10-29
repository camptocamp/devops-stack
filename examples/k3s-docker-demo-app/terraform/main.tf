locals {
  repo_url        = "https://github.com/camptocamp/camptocamp-devops-stack.git"
  target_revision = "v0.10.0"

  base_domain                       = module.cluster.base_domain
  kubernetes_host                   = module.cluster.kubernetes_host
  kubernetes_username               = module.cluster.kubernetes_username
  kubernetes_password               = module.cluster.kubernetes_password
  kubernetes_cluster_ca_certificate = module.cluster.kubernetes_cluster_ca_certificate
}

module "cluster" {
  source = "git::https://github.com/camptocamp/camptocamp-devops-stack.git//modules/k3s-docker?ref=v0.10.0"

  cluster_name = terraform.workspace
  node_count   = 1

  repo_url        = local.repo_url
  target_revision = local.target_revision
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

resource "helm_release" "project_apps" {
  name              = "project-apps"
  chart             = "${path.module}/../argocd/project-apps"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    <<EOT
---
spec:
  source:
    repoURL: ${local.repo_url}
    targetRevision: ${local.target_revision}

baseDomain: ${local.base_domain}
          EOT
  ]

  depends_on = [
    module.cluster,
  ]
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
  backend                          = local.kubernetes_vault_auth_backend_path
  role_name                        = "minio"
  bound_service_account_names      = ["minio", "secrets-store-csi-driver"]
  bound_service_account_namespaces = ["minio", "secrets-store-csi-driver"]
  token_ttl                        = 3600
  token_policies                   = ["default", vault_policy.demo_app.name]
}