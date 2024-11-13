##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
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
    fmg_username           = var.username
    fmg_public_ip_address  = data.azurerm_public_ip.fmgpip.ip_address
    fmg_private_ip_address = azurerm_network_interface.fmgifc.private_ip_address
  })
}

data "azurerm_public_ip" "fmgpip" {
  name                = azurerm_public_ip.fmgpip.name
  resource_group_name = var.resource_group_name
}

output "fmg_public_ip_address" {
  value = data.azurerm_public_ip.fmgpip.ip_address
}
