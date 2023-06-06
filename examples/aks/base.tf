data "azuread_client_config" "current" {
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "state" {
  name     = "state-file"
  location = "France Central"

}

# resource "azurerm_resource_group" "default" {
#   name     = "devops-stack"
#   location = "France Central"
# }
