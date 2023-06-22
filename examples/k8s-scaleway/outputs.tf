output "kubeconfig_file" {
  sensitive = true
  value     = module.scaleway.kubeconfig_file
}

#output "lb_ip_address" {
#  value = scaleway_lb_ip.this.ip_address
#}
#
#output "lb_id" {
#  value = scaleway_lb.this.id
#}

