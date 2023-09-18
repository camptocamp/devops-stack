resource "azurerm_dns_zone" "this" {
  name                = "hello-ds.camptocamp.com"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_dns_cname_record" "wildcard" {
  name                = "*.apps"
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = azurerm_resource_group.default.name
  ttl                 = 300
  record              = format("%s-%s.%s.cloudapp.azure.com.", local.cluster_name, replace(azurerm_dns_zone.this.name, ".", "-"), azurerm_resource_group.default.location)
}
