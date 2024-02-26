##############################################################################################################
#
# FortiGate a standalone FortiGate VM-DualStack
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    username                   = var.USERNAME
    location                   = var.LOCATION
    fgt_ipv4address              = data.azurerm_public_ip.fgtpipv4.ip_address
	fgt_ipv6address              = data.azurerm_public_ip.fgtpipv6.ip_address
    fgt_private_ip_address_ext = azurerm_network_interface.fgtifcext.private_ip_address
    fgt_private_ip_address_int = azurerm_network_interface.fgtifcint.private_ip_address
  })
}
