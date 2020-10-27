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

provider "kubernetes-alpha" {
  host                   = local.kubernetes_host
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.kubernetes_ca_cert
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
  namespace         = "argocd"
  chart             = "${path.module}/../../argocd/argocd/"
  dependency_update = true
  create_namespace  = true

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
