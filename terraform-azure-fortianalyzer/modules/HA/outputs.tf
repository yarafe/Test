##############################################################################################################
#
# FortiAnalyzer - HA FortiAnalyzer VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tftpl", {
    location               = var.location
    faz_username           = var.username
    faz1_public_ip_address  = data.azurerm_public_ip.faz1pip.ip_address
    faz1_private_ip_address = azurerm_network_interface.faz1ifc.private_ip_address
	faz2_public_ip_address  = data.azurerm_public_ip.faz2pip.ip_address
    faz2_private_ip_address = azurerm_network_interface.faz2ifc.private_ip_address
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

