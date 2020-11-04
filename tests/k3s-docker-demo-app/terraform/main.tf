locals {
  base_domain                        = module.cluster.base_domain
  kubernetes_host                    = module.cluster.kubernetes_host
  kubernetes_username                = module.cluster.kubernetes_username
  kubernetes_password                = module.cluster.kubernetes_password
  kubernetes_cluster_ca_certificate  = module.cluster.kubernetes_cluster_ca_certificate
  kubernetes_vault_auth_backend_path = module.cluster.kubernetes_vault_auth_backend_path
}

module "cluster" {
  source = "../../../modules/k3s-docker"

  cluster_name = terraform.workspace
  node_count   = 1

  repo_url        = var.repo_url
  target_revision = var.target_revision
}

provider "kubernetes-alpha" {
  host                   = local.kubernetes_host
  username               = local.kubernetes_username
  password               = local.kubernetes_password
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

provider "vault" {
  address         = format("https://vault.apps.%s", local.base_domain)
  token           = "root"
  skip_tls_verify = true
}

resource "kubernetes_manifest" "project_apps" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "project-apps"
      "namespace" = "argocd"
      "annotations" = {
        "argocd.argoproj.io/sync-wave" = "15"
      }
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "path"           = "examples/k3s-docker-demo-app/argocd/project-apps"
        "repoURL"        = var.repo_url
        "targetRevision" = var.target_revision
        "helm" = {
          "values" = <<EOT
---
spec:
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}

baseDomain: ${local.base_domain}
          EOT
        }
      }
      "destination" = {
        "namespace" = "default"
        "server"    = "https://kubernetes.default.svc"
      }
      "syncPolicy" = {
        "automated" = {
          "selfHeal" = true
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      object,
    ]
  }
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
