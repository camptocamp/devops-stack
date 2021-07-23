output "kubeconfig" {
  sensitive = true
  value     = module.cluster.kubeconfig
}

#output "node_ids" {
#  value = data.opentelekomcloud_cce_node_ids_v3.node_ids.ids
#}

output "node_ips" {
  value = data.opentelekomcloud_cce_node_v3.node_ips.*.public_ip
}
