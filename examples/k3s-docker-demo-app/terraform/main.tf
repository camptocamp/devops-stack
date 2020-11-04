locals {
  repo_url        = "https://github.com/camptocamp/camptocamp-devops-stack.git"
  target_revision = "HEAD"

  base_domain                        = module.cluster.base_domain
  kubernetes_host                    = module.cluster.kubernetes_host
  kubernetes_username                = module.cluster.kubernetes_username
  kubernetes_password                = module.cluster.kubernetes_password
  kubernetes_cluster_ca_certificate  = module.cluster.kubernetes_cluster_ca_certificate
  kubernetes_vault_auth_backend_path = module.cluster.kubernetes_vault_auth_backend_path
}

module "cluster" {
  source = "git::https://github.com/camptocamp/camptocamp-devops-stack.git//modules/k3s-docker?ref=HEAD"

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

provider "vault" {
  address         = format("https://vault.apps.%s", local.base_domain)
  token           = "root"
  skip_tls_verify = true
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

resource "random_password" "superdupersecret" {
  length           = 128
  special          = true
  override_special = "_%@"
}

resource "vault_generic_secret" "demo_app" {
  path = "secret/demo-app"

  data_json = <<EOT
{
  "foo":   "${random_password.superdupersecret.result}",
  "pizza": "cheese"
}
EOT
}

resource "vault_policy" "demo_app" {
  name = "demo-app"

  policy = <<EOT
path "secret/data/demo-app" {
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

resource "vault_kubernetes_auth_backend_role" "demo_app" {
  backend                          = local.kubernetes_vault_auth_backend_path
  role_name                        = "demo-app"
  bound_service_account_names      = ["demo-app", "secrets-store-csi-driver"]
  bound_service_account_namespaces = ["demo-app", "secrets-store-csi-driver"]
  token_ttl                        = 3600
  token_policies                   = ["default", vault_policy.demo_app.name]
}
