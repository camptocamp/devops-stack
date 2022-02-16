locals {
  docker_gateway                    = compact(data.docker_network.kind.ipam_config[*].gateway)[0]
  base_domain                       = coalesce(var.base_domain, format("%s.nip.io", replace(local.docker_gateway, ".", "-")))
  kubernetes_host                   = kind_cluster.cluster.endpoint
  kubernetes_client_certificate     = kind_cluster.cluster.client_certificate
  kubernetes_client_key             = kind_cluster.cluster.client_key
  kubernetes_cluster_ca_certificate = kind_cluster.cluster.cluster_ca_certificate
  kubeconfig                        = kind_cluster.cluster.kubeconfig
}

data "docker_network" "kind" {
  name = "kind"
  depends_on = [ kind_cluster.cluster ]
}

resource "kind_cluster" "cluster" {
  name = var.cluster_name

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }
  }
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
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//modules/bootstrap"

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

  repositories = var.repositories
  
  depends_on = [
    kind_cluster.cluster,
  ]
}
