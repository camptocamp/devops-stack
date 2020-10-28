locals {
  base_domain        = format("%s.nip.io", replace(module.cluster.ingress_ip_address, ".", "-"))
  context            = yamldecode(module.cluster.kubeconfig)
  kubernetes_host    = local.context.clusters.0.cluster.server
  kubernetes_ca_cert = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  client_certificate = base64decode(local.context.users.0.user.client-certificate-data)
  client_key         = base64decode(local.context.users.0.user.client-key-data)
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    client_certificate     = local.client_certificate
    client_key             = local.client_key
    cluster_ca_certificate = local.kubernetes_ca_cert
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.kubernetes_ca_cert
}

provider "kubernetes-alpha" {
  host                   = local.kubernetes_host
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.kubernetes_ca_cert
}

provider "vault" {
  address      = format("https://vault.apps.%s", local.base_domain)
  token        = "root"
  ca_cert_file = local_file.vault_cert.filename
}

module "cluster" {
  source  = "camptocamp/k3s/docker"
  version = "0.1.0"

  cluster_name = var.cluster_name
  k3s_version  = var.k3s_version
  node_count   = var.node_count
}

resource "helm_release" "argocd" {
  name              = "argocd"
  repository        = "https://argoproj.github.io/argo-helm"
  chart             = "argo-cd"
  version           = "2.7.4"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    <<EOT
---
installCRDs: false
configs:
  secret:
    argocdServerAdminPassword: "$2a$10$wzUzrdx.jMb7lHIbW6VutuRpV4OnpPA3ItWBDiP04QVHfGqzAoj6i"  # argocd
    argocdServerAdminPasswordMtime: '2020-07-23T11:31:23Z'
server:
  extraArgs:
    - --insecure
  config:
    accounts.pipeline: apiKey
    resource.customizations: |
      networking.k8s.io/Ingress:
        health.lua: |
          hs = {}
          hs.status = "Healthy"
          return hs
  EOT
  ]

  depends_on = [
    module.cluster,
  ]
}

resource "kubernetes_manifest" "app_of_apps" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "apps"
      "namespace" = "argocd"
      "annotations" = {
        "argocd.argoproj.io/sync-wave" = "5"
      }
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "path"           = "argocd/apps"
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

apps:
  demo-app:
    enabled: false
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

  depends_on = [
    helm_release.argocd,
  ]
}

resource "null_resource" "wait_for_vault" {
  depends_on = [
    kubernetes_manifest.app_of_apps,
  ]

  provisioner "local-exec" {
    command = "for i in `seq 1 60`; do kubectl get ns vault && break || sleep 5; done; for i in `seq 1 60`; do test \"`kubectl -n vault get pods --selector 'app.kubernetes.io/name=vault' --output=name | wc -l`\" -ne 0 && exit 0 || sleep 5; done; echo TIMEOUT && exit 1"

    environment = {
      KUBECONFIG = module.cluster.kubeconfig_filename
    }
  }
}

data "kubernetes_ingress" "vault" {
  metadata {
    name      = "vault"
    namespace = "vault"
  }

  depends_on = [
    kubernetes_manifest.app_of_apps,
  ]
}

data "kubernetes_secret" "vault" {
  metadata {
    name      = data.kubernetes_ingress.vault.spec.0.tls.0.secret_name
    namespace = "vault"
  }
}

resource "local_file" "vault_cert" {
  content  = lookup(data.kubernetes_secret.vault.data, "ca.crt")
  filename = "${path.module}/vault.crt"
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"

  depends_on = [
    null_resource.wait_for_vault,
  ]
}

resource "vault_kubernetes_auth_backend_config" "in_cluster" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = local.kubernetes_host
  kubernetes_ca_cert = local.kubernetes_ca_cert
}
