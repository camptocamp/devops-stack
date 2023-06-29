locals {
  context                           = yamldecode(ovh_cloud_project_kube.k8s_cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)
}

# 1. Création du réseau privé
resource "ovh_cloud_project_network_private" "network" {
  vlan_id = var.vlan_id
  name    = var.vlan_name
  regions = [var.cluster_region]
}

# 2. Création du sous-réseau privé
resource "ovh_cloud_project_network_private_subnet" "networksubnet" {
  network_id = ovh_cloud_project_network_private.network.id

  region     = var.cluster_region
  start      = var.vlan_subnet_start
  end        = var.vlan_subnet_end
  network    = var.vlan_subnet_network
  dhcp       = true
  no_gateway = false

  depends_on = [ovh_cloud_project_network_private.network]
}

# 3. Provisionnement du Cluster K8S
resource "ovh_cloud_project_kube" "k8s_cluster" {
  name   = var.cluster_name
  region = var.cluster_region

  private_network_id = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]

  private_network_configuration {
    default_vrack_gateway              = ""
    private_network_routing_as_default = false
  }

  depends_on = [ovh_cloud_project_network_private.network]
}

# 4. Provisionnement du Node-Pool
resource "ovh_cloud_project_kube_nodepool" "k8s_node_pool" {
  kube_id       = ovh_cloud_project_kube.k8s_cluster.id
  flavor_name   = var.flavor_name
  desired_nodes = var.desired_nodes
  max_nodes     = var.max_nodes
  min_nodes     = var.min_nodes

  depends_on = [ovh_cloud_project_kube.k8s_cluster]
}

# 5. Création d'un panier
data "ovh_order_cart" "mycart" {
  ovh_subsidiary = "fr"
}

# 5.1. Ajout de la zone DNS
data "ovh_order_cart_product_plan" "zone" {
  cart_id        = data.ovh_order_cart.mycart.id
  price_capacity = "renew"
  product        = "dns"
  plan_code      = "zone"
}

# 5.2. Ajout du domaine
resource "ovh_domain_zone" "zone" {
  ovh_subsidiary = data.ovh_order_cart.mycart.ovh_subsidiary

  plan {
    duration     = data.ovh_order_cart_product_plan.zone.selected_price.0.duration
    plan_code    = data.ovh_order_cart_product_plan.zone.plan_code
    pricing_mode = data.ovh_order_cart_product_plan.zone.selected_price.0.pricing_mode

    configuration {
      label = "zone"
      value = format("%s.%s", var.cluster_name, var.base_domain)
    }

    configuration {
      label = "template"
      value = "minimized"
    }
  }
}
