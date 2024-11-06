##############################################################################################################
#
# FortiAnalyzer - High Availability  FortiAnalyzer VM-A
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
# Main
##############################################################################################################
locals {
  faz1_name = "${var.prefix}-faz1"
  faz1_vars = {
    faz1_vm_name           = "${local.faz1_name}"
    faz1_license_file      = var.faz1_byol_license_file
    faz1_license_fortiflex = var.faz1_byol_fortiflex_license_token
	faz1_byol_serial_number = var.faz1_byol_serial_number
    faz_username          = var.username
    faz_ssh_public_key    = var.faz_ssh_public_key_file
    faz1_ipaddr            = azurerm_network_interface.faz1ifc.private_ip_address
    faz_mask              = cidrnetmask(var.subnet_prefixes[0])	  
    faz_gw                = cidrhost(var.subnet_prefixes[0], 1)
	ha_ip		  		  = var.ha_ip
	ha_ip_address		  = var.ha_ip == "public" ? azurerm_public_ip.hapip[0].ip_address : azurerm_network_interface.faz1ifc.ip_configuration[1].private_ip_address
  }
  
  faz2_name = "${var.prefix}-faz2"
  faz2_vars = {
    faz2_vm_name           = "${local.faz2_name}"
    faz2_license_file      = var.faz2_byol_license_file
    faz2_license_fortiflex = var.faz2_byol_fortiflex_license_token
	faz2_byol_serial_number	= var.faz2_byol_serial_number
    faz_username          = var.username
    faz_ssh_public_key    = var.faz_ssh_public_key_file
	faz2_ipaddr            = azurerm_network_interface.faz2ifc.private_ip_address
    faz_mask              = cidrnetmask(var.subnet_prefixes[0])
    faz_gw                = cidrhost(var.subnet_prefixes[0], 1)
  }
  
  faz_combined_vars = merge(local.faz1_vars, local.faz2_vars)
  faz1_customdata = base64encode(templatefile("${path.module}/faz1-customdata.tftpl", local.faz_combined_vars))
  faz2_customdata = base64encode(templatefile("${path.module}/faz2-customdata.tftpl", local.faz_combined_vars))
  

  faz_plan = {
    publisher = "fortinet"
    product   = "fortinet-fortianalyzer"
    name      = "fortinet-fortianalyzer"
  }

}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.prefix}-rg"
  location = var.location

  lifecycle {
    ignore_changes = [tags["CreatedOnDate"]]
  }
}

resource "azurerm_network_security_group" "faznsg" {
  name                = "${var.prefix}-faz-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "faznsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowlogsin" {
  name                        = "AllowLogsInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "514"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowhain" {
  name                        = "AllowHAInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 160
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5199"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "faz1pip" {
  name                = "${local.faz1_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "faz1", random_string.random.result)
}

resource "azurerm_public_ip" "faz2pip" {
  name                = "${local.faz2_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "faz2", random_string.random.result)
}

resource "azurerm_public_ip" "hapip" {
  count               = var.ha_ip == "public" ? 1 : 0
  name                = "ha-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "ha", random_string.random.result)
}

resource "azurerm_network_interface" "faz1ifc" {
  name                 = "${local.faz1_name}-nic1"
  location             = var.location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.faz1pip.id
	primary                       = true
  }
  ip_configuration {
    name                          = "vip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.ha_ip == "public" ? azurerm_public_ip.hapip[0].id : null
	primary                       = false
  }

  lifecycle {
    ignore_changes = [ip_configuration["subnet_id"]]
  }
}

resource "azurerm_network_interface" "faz2ifc" {
  name                 = "${local.faz2_name}-nic1"
  location             = var.location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.faz2pip.id
	primary                       = true
  }
  dynamic "ip_configuration" {
  for_each = var.ha_ip == "public" ? [1] : []
  content {
    name                          = "vip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
	primary                       = false
   }
  }
  lifecycle {
    ignore_changes = [ip_configuration["subnet_id"]]
  }
}

resource "azurerm_network_interface_security_group_association" "faznsg" {
  count					    = 2
  network_interface_id      = count.index == 0 ? azurerm_network_interface.faz1ifc.id : azurerm_network_interface.faz2ifc.id
  network_security_group_id = azurerm_network_security_group.faznsg.id
}

resource "azurerm_linux_virtual_machine" "faz" {
  count					= 2
  name                  = "${var.prefix}-faz${count.index+1}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [
    count.index == 0 ? azurerm_network_interface.faz1ifc.id : azurerm_network_interface.faz2ifc.id
  ]
  size                  = var.faz_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_id = var.faz_source_image_id

  dynamic "source_image_reference" {
    for_each = var.faz_source_image_id == null ? toset([1]) : toset([])
    content {
      publisher = "fortinet"
      offer     = "fortinet-fortianalyzer"
      sku       = "fortinet-fortianalyzer"
      version   = var.faz_version
    }
  }

  dynamic "plan" {
    for_each = var.faz_source_image_id == null ? toset([1]) : toset([])
    content {
      publisher = "fortinet"
      product   = "fortinet-fortianalyzer"
      name      = "fortinet-fortianalyzer"
    }
  }

  os_disk {
    name                 = "${var.prefix}-faz${count.index+1}-osdisk"      
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data                     = count.index == 0 ? local.faz1_customdata : local.faz2_customdata

  boot_diagnostics {
  }

  tags = var.fortinet_tags

  lifecycle {
    ignore_changes = [custom_data]
  }
}

resource "azurerm_managed_disk" "faz1-datadisk" {
  count                = var.faz_datadisk_count
  name                 = "${local.faz1_name}-datadisk-${count.index+1}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.faz_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.faz_datadisk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "faz1-datadisk-attach" {
  count              = var.faz_datadisk_count
  managed_disk_id    = element(azurerm_managed_disk.faz1-datadisk.*.id, count.index)
  virtual_machine_id = azurerm_linux_virtual_machine.faz[0].id
  lun                = count.index
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "faz2-datadisk" {
  count                = var.faz_datadisk_count
  name                 = "${local.faz2_name}-datadisk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.faz_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.faz_datadisk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "faz2-datadisk-attach" {
  count              = var.faz_datadisk_count
  managed_disk_id    = element(azurerm_managed_disk.faz2-datadisk.*.id, count.index)
  virtual_machine_id = azurerm_linux_virtual_machine.faz[1].id
  lun                = count.index
  caching            = "ReadWrite"
}


resource "azurerm_role_assignment" "network_contributor_faz1" {
  scope                = azurerm_resource_group.resourcegroup.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_linux_virtual_machine.faz[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "network_contributor_faz2" {
  scope                = azurerm_resource_group.resourcegroup.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_linux_virtual_machine.faz[1].identity[0].principal_id
}