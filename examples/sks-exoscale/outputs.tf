#output "base_domain" {
#  value = module.sks.base_domain
#}
#
#output "argocd_auth_token" {
#  sensitive = true
#  value     = module.sks.argocd_auth_token
#}
#
#output "argocd_server_admin_password" {
#  sensitive = true
#  value     = module.sks.argocd_server_admin_password
#}
#
#output "kubeconfig" {
#  sensitive = true
#  value     = module.sks.kubeconfig
#}
#
#output "argocd_server" {
#  value = module.sks.argocd_server
#}
#
#output "repo_url" {
#  value = module.sks.repo_url
#}
#
#output "target_revision" {
#  value = module.sks.target_revision
#}
#
#output "argocd_url" {
#  value = format("https://argocd.apps.%s.%s", var.cluster_name, module.sks.base_domain)
#}
#
#output "grafana_url" {
#  value = format("https://grafana.apps.%s.%s", var.cluster_name, module.sks.base_domain)
#}
#
#output "prometheus_url" {
#  value = format("https://prometheus.apps.%s.%s", var.cluster_name, module.sks.base_domain)
#}
#
#output "alertmanager_url" {
#  value = format("https://alertmanager.apps.%s.%s", var.cluster_name, module.sks.base_domain)
#}
