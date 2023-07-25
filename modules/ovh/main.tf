locals {
  context                           = yamldecode(ovh_cloud_project_kube.k8s_cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)
}


# 1. Provisionnement du Cluster K8S
resource "ovh_cloud_project_kube" "k8s_cluster" {
  name   = var.cluster_name
  region = var.cluster_region
}

# 2. Provisionnement du Node-Pool
resource "ovh_cloud_project_kube_nodepool" "k8s_node_pool" {
  kube_id       = ovh_cloud_project_kube.k8s_cluster.id
  flavor_name   = var.flavor_name
  desired_nodes = var.desired_nodes
  max_nodes     = var.max_nodes
  min_nodes     = var.min_nodes
  autoscale     = true

  depends_on = [ovh_cloud_project_kube.k8s_cluster]
}

# 3. Création d'un panier
data "ovh_order_cart" "mycart" {
  ovh_subsidiary = "fr"
}

# 3.1. Ajout de la zone DNS
data "ovh_order_cart_product_plan" "zone" {
  cart_id        = data.ovh_order_cart.mycart.id
  price_capacity = "renew"
  product        = "dns"
  plan_code      = "zone"
}

# 3.2. Ajout du domaine
resource "ovh_domain_zone" "zone" {
  ovh_subsidiary = data.ovh_order_cart.mycart.ovh_subsidiary

  plan {
    duration     = data.ovh_order_cart_product_plan.zone.selected_price.0.duration
    plan_code    = data.ovh_order_cart_product_plan.zone.plan_code
    pricing_mode = data.ovh_order_cart_product_plan.zone.selected_price.0.pricing_mode

    configuration {
      label = "zone"
      value = format("%s", var.base_domain)
    }

    configuration {
      label = "template"
      value = "minimized"
    }
  }
}
