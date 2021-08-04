output "node_ips" {
  description = "nodes public IPs"
  value       = module.cluster.node_ips
}

output "elb_ip" {
  value = opentelekomcloud_lb_loadbalancer_v2.ingress.vip_address
}

