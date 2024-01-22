resource "azurerm_dns_zone" "this" {
  name                = "your.domain.here"
  resource_group_name = resource.azurerm_resource_group.default.name
}
