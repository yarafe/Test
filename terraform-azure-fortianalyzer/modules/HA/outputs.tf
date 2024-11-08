##############################################################################################################
#
# FortiAnalyzer - HA FortiAnalyzer Active/Passive
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tftpl", {
    location                = var.location
    faz_username            = var.username
    faz1_public_ip_address  = data.azurerm_public_ip.faz1pip.ip_address
    faz1_private_ip_address = azurerm_network_interface.faz1ifc.private_ip_address
	  faz2_public_ip_address  = data.azurerm_public_ip.faz2pip.ip_address
    faz2_private_ip_address = azurerm_network_interface.faz2ifc.private_ip_address
    ha_ip_address           =  var.ha_ip == "public" && length(data.azurerm_public_ip.hapip) > 0 ? data.azurerm_public_ip.hapip[0].ip_address : azurerm_network_interface.faz1ifc.ip_configuration[1].private_ip_address
  })
}

data "azurerm_public_ip" "faz1pip" {
  name                = azurerm_public_ip.faz1pip.name
  resource_group_name = var.resource_group_name
}

output "faz1_public_ip_address" {
  value = data.azurerm_public_ip.faz1pip.ip_address
}

data "azurerm_public_ip" "faz2pip" {
  name                = azurerm_public_ip.faz2pip.name
  resource_group_name = var.resource_group_name
}

output "faz2_public_ip_address" {
  value = data.azurerm_public_ip.faz2pip.ip_address
}

data "azurerm_public_ip" "hapip" {
  count               = var.ha_ip == "public" ? 1 : 0
  name                = var.ha_ip == "public" ? azurerm_public_ip.hapip[0].name : ""
  resource_group_name = var.resource_group_name
}

output "ha_ip_address" {
  value = var.ha_ip == "public" && length(data.azurerm_public_ip.hapip) > 0 ? data.azurerm_public_ip.hapip[0].ip_address : azurerm_network_interface.faz1ifc.ip_configuration[1].private_ip_address
}