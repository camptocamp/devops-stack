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
    insecure = true
    host     = local.kubernetes_host
    username = local.kubernetes_username
    password = local.kubernetes_password
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  username               = local.kubernetes_username
  password               = local.kubernetes_password
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
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

module "cluster" {
  source  = "camptocamp/k3os/libvirt"
  version = "0.2.0"

  cluster_name = var.cluster_name
  k3os_version = var.k3os_version
  node_count   = var.node_count

  server_memory = 2048
  agent_memory  = 2048
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
          "values" = templatefile("${path.module}/values.tmpl.yaml",
            {
              cluster_name    = var.cluster_name,
              base_domain     = local.base_domain,
              repo_url        = var.repo_url,
              target_revision = var.target_revision,
            }
          )
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

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"

  depends_on = [
    null_resource.wait_for_vault,
  ]
}

resource "vault_kubernetes_auth_backend_config" "in_cluster" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = local.kubernetes_host
  kubernetes_ca_cert = local.kubernetes_cluster_ca_certificate
}
