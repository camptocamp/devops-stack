output "base_domain" {
  value = module.cluster.base_domain
}

output "argocd_url" {
  value = format("https://argocd.apps.%s", module.cluster.base_domain)
}

output "grafana_url" {
  value = format("https://grafana.apps.%s", module.cluster.base_domain)
}

output "prometheus_url" {
  value = format("https://prometheus.apps.%s", module.cluster.base_domain)
}

output "alertmanager_url" {
  value = format("https://alertmanager.apps.%s", module.cluster.base_domain)
}
