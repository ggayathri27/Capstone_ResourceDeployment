# Resource-1: Create Public IP Address

locals {
  resource_name_prefix = "webapp"
}

resource "azurerm_public_ip" "web_linuxvm_publicip" {
  name                = "${local.resource_name_prefix}-linuxvm-publicip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku = "Standard"
  #domain_name_label = "app1-vm-${random_string.myrandom.id}"
}