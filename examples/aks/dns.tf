# Use these resources if you are creating the DNS zone using this code specifically for this deployment (so we will 
# deploy the DNS zone on the same resource group).

resource "azurerm_dns_zone" "this" {
  name                = local.base_domain
  resource_group_name = resource.azurerm_resource_group.main.name
}

# This resource should be deactivated if there are multiple development clusters on the same account.
resource "azurerm_dns_cname_record" "wildcard" {
  count = local.activate_wildcard_record ? 1 : 0

  zone_name           = resource.azurerm_dns_zone.this.name
  name                = local.subdomain != "" ? "*.${local.subdomain}" : "*"
  resource_group_name = resource.azurerm_resource_group.main.name
  ttl                 = 300
  record              = format("%s-%s.%s.cloudapp.azure.com.", module.aks.cluster_name, replace(resource.azurerm_dns_zone.this.name, ".", "-"), resource.azurerm_resource_group.main.location)
}

# Else use these resources if you are using an existing DNS zone.

# data "azurerm_dns_zone" "this" {
#   name                = local.base_domain
#   resource_group_name = local.default_resource_group
# }

# # This resource should be deactivated if there are multiple development clusters on the same account.
# resource "azurerm_dns_cname_record" "wildcard" {
#   count = local.activate_wildcard_record ? 1 : 0

#   zone_name           = data.azurerm_dns_zone.this.name
#   name                = "*.apps"
#   resource_group_name = local.default_resource_group
#   ttl                 = 300
#   record              = format("%s-%s.%s.cloudapp.azure.com.", module.aks.cluster_name, replace(data.azurerm_dns_zone.this.name, ".", "-"), resource.azurerm_resource_group.main.location)
# }
