output "argocd_url" {
  value = format("https://argocd.apps.%s.%s", local.cluster_name, azurerm_dns_zone.this.name)
}
