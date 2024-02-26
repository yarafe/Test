##############################################################################################################
#
# FortiGate a standalone FortiGate VM-DualStack
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.PREFIX}-FGT-NSG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fgtnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fgtnsgallowallin" {
  name                        = "AllowAllInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fgtpipv4" {
  name                = "${var.PREFIX}-FGT-PIPv4"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lb-pipv4")
}

resource "azurerm_public_ip" "fgtpipv6" {
  name                = "${var.PREFIX}-FGT-PIPv6"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version		  = "IPv6"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lb-pipv6")
}

resource "azurerm_network_interface" "fgtifcext" {
  name                          = "${var.PREFIX}-FGT-Nic1-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
	primary 					  = "true"
    private_ip_address            = var.fgt_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.fgtpipv4.id
  }
  ip_configuration {
    name                          = "interfaceIPv6"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
	private_ip_address_version 	  = "IPv6"
    private_ip_address            = var.fgt_ipaddress["4"]
    public_ip_address_id          = azurerm_public_ip.fgtpipv6.id
  }
  ip_configuration {
    name                          = "interface2"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["3"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcextnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcext.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface" "fgtifcint" {
  name                 = "${var.PREFIX}-FGT-Nic2-INT"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
	primary 					  = "true"
    private_ip_address            = var.fgt_ipaddress["5"]
  }
  ip_configuration {
    name                          = "interfaceIPv6"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
	private_ip_address_version 	  = "IPv6"
    private_ip_address            = var.fgt_ipaddress["6"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcintnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcint.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_linux_virtual_machine" "fgtvm" {
  name                         = "${var.PREFIX}-FGT"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.fgtifcext.id, azurerm_network_interface.fgtifcint.id]
  size                         = var.fgt_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.FGT_IMAGE_SKU
    version   = var.FGT_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.FGT_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.PREFIX}-FGT-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fgt_vm_name         	= "${var.PREFIX}-FGT"
    fgt_license_file    	= var.FGT_BYOL_LICENSE_FILE
    fgt_license_fortiflex  	= var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN
    fgt_username        	= var.USERNAME
    fgt_ssh_public_key  	= var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_ipv4addr1 	= var.fgt_ipaddress["1"]
	fgt_external_ipv4addr2 	= var.fgt_ipaddress["3"]
	fgt_external_ipv6addr1 	= var.fgt_ipaddress["2"]
	fgt_external_ipv6addr2 	= var.fgt_ipaddress["4"]
    fgt_external_mask_ipv4  = var.subnetmask["1"]
	fgt_external_mask_ipv6  = var.subnetmask["5"]
    fgt_external_gw_ipv4    = var.gateway_ipaddress["1"]
	fgt_external_gw_ipv6    = var.gateway_ipaddress["3"]
    fgt_internal_ipv4addr 	= var.fgt_ipaddress["5"]
	fgt_internal_ipv6addr 	= var.fgt_ipaddress["6"]
    fgt_internal_mask_ipv4  = var.subnetmask["2"]
	fgt_internal_mask_ipv6  = var.subnetmask["6"]
    fgt_internal_gw_ipv4    = var.gateway_ipaddress["2"]
	fgt_internal_gw_ipv6    = var.gateway_ipaddress["4"]
    fgt_protected_net_ipv4  = var.subnet["3"]
	fgt_protected_net_ipv6  = var.subnet["7"]
    vnet_network_ipv4       = var.vnet["1"]
	vnet_network_ipv6       = var.vnet["2"]
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "fgtvm-datadisk" {
  name                 = "${var.PREFIX}-FGT-DATADISK"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "fgtvm-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.fgtvm-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fgtvm.id
  lun                = 0
  caching            = "ReadWrite"
}

data "azurerm_public_ip" "fgtpipv4" {
  name                = azurerm_public_ip.fgtpipv4.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_linux_virtual_machine.fgtvm]
}

data "azurerm_public_ip" "fgtpipv6" {
  name                = azurerm_public_ip.fgtpipv6.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_linux_virtual_machine.fgtvm]
}
output "fgt_public_ipv4_address" {
  value = data.azurerm_public_ip.fgtpipv4.ip_address
}
output "fgt_public_ipv6_address" {
  value = data.azurerm_public_ip.fgtpipv6.ip_address
}