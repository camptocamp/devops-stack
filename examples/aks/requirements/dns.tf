resource "azurerm_dns_zone" "this" {
  name                = local.base_domain
  resource_group_name = resource.azurerm_resource_group.default.name
}
