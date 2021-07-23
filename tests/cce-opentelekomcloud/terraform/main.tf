#locals {
#  ingress_listeners = [
#    80,
#    443,
#  ]
#}


module "cluster" {
  source = "../../../modules/cce/opentelekomcloud"

  app_of_apps_values_overrides = var.app_of_apps_values_overrides

  cluster_name = "test"
  base_domain  = var.base_domain

  repo_url        = var.repo_url
  target_revision = var.target_revision

  subnet_id = var.subnet_id
  flavor_id = "cce.s2.small"
  vpc_id    = var.vpc_id

  node_pools = {
    "worker-01" = {
      flavor             = "s2.xlarge.2"
      initial_node_count = 1
      availability_zone  = "eu-de-01"
      key_pair           = var.key_pair
      postinstall        = var.postinstall
    },
    "worker-02" = {
      flavor             = "s2.xlarge.2"
      initial_node_count = 1
      availability_zone  = "eu-de-02"
      key_pair           = var.key_pair
      postinstall        = var.postinstall
    },
    "worker-03" = {
      flavor             = "s2.xlarge.2"
      initial_node_count = 1
      availability_zone  = "eu-de-03"
      key_pair           = var.key_pair
      postinstall        = var.postinstall
    },
  }
}

#data "opentelekomcloud_cce_node_ids_v3" "node_ids" {
#  cluster_id = var.cluster_id
#}

data "opentelekomcloud_cce_node_v3" "node_ip" {
  cluster_id = var.cluster_id
}



#resource "opentelekomcloud_lb_loadbalancer_v2" "ingress" {
#  name          = "devopsstack-ingress"
#  vip_subnet_id = var.subnet_id
#  #vip_address   = cidrhost(var.cidr, 3)
#
#  #security_group_ids = [
#  #  data.opentelekomcloud_networking_secgroup_v2.FTTH_default.id,
#  #  data.opentelekomcloud_networking_secgroup_v2.FTTH_custom_default.id,
#}
#
#resource "opentelekomcloud_lb_listener_v2" "ingress" {
#  count           = length(local.ingress_listeners)
#  protocol        = "TCP"
#  protocol_port   = local.ingress_listeners[count.index]
#  loadbalancer_id = opentelekomcloud_lb_loadbalancer_v2.ingress.id
#}
#
#resource "opentelekomcloud_lb_pool_v2" "ingress_haproxy" {
#  count       = length(local.ingress_listeners)
#  protocol    = "TCP"
#  lb_method   = "ROUND_ROBIN"
#  listener_id = opentelekomcloud_lb_listener_v2.ingress[count.index].id
#}
#
#resource "opentelekomcloud_lb_member_v2" "ingress_haproxy" {
#  count = 3 * length(local.ingress_listeners)
#
#  pool_id       = opentelekomcloud_lb_pool_v2.ingress_haproxy[abs(format("%0.f", count.index - 1 + 0.5) / 2)].id
#  subnet_id     = var.subnet_id
#  address       = module.haproxy.this_compute_instance_v2_access_ip_v4s[count.index % 2]
#  protocol_port = local.ingress_listeners[abs(format("%0.f", count.index - 1 + 0.5) / 2)]
#}
#
