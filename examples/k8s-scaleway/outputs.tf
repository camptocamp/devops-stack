output "argocd_server_admin_password" {
  description = "Argocd admin password"
  sensitive   = true
  value       = module.argocd_bootstrap.argocd_server_admin_password
}

#output "lb_ip_address" {
#  value = scaleway_lb_ip.this.ip_address
#}
#
#output "lb_id" {
#  value = scaleway_lb.this.id
#}

