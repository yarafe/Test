##############################################################################################################
#
# FortiManager - High Availability  
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
# Main
##############################################################################################################
locals {
  fmg1_name = "${var.prefix}-fmg1"
  fmg1_vars = {
    fmg1_vm_name            = "${local.fmg1_name}"
    fmg1_license_file       = var.fmg1_byol_license_file
    fmg1_license_fortiflex  = var.fmg1_byol_fortiflex_license_token
    fmg1_byol_serial_number = var.fmg1_byol_serial_number
    fmg_username            = var.username
    fmg_ssh_public_key      = var.fmg_ssh_public_key_file
    fmg1_ipaddr             = azurerm_network_interface.fmg1ifc.private_ip_address
    fmg_mask                = cidrnetmask(var.subnet_prefixes[0])
    fmg_gw                  = cidrhost(var.subnet_prefixes[0], 1)
    ha_ip		    = var.ha_ip
    ha_ip_address           = var.ha_ip == "public" ? azurerm_public_ip.hapip[0].ip_address : azurerm_network_interface.fmg1ifc.ip_configuration[1].private_ip_address
  }
  
  fmg2_name = "${var.prefix}-fmg2"
  fmg2_vars = {
    fmg2_vm_name            = "${local.fmg2_name}"
    fmg2_license_file       = var.fmg2_byol_license_file
    fmg2_license_fortiflex  = var.fmg2_byol_fortiflex_license_token
    fmg2_byol_serial_number = var.fmg2_byol_serial_number
    fmg_username            = var.username
    fmg_ssh_public_key      = var.fmg_ssh_public_key_file
    fmg2_ipaddr             = azurerm_network_interface.fmg2ifc.private_ip_address
    fmg_mask                = cidrnetmask(var.subnet_prefixes[0])
    fmg_gw                  = cidrhost(var.subnet_prefixes[0], 1)
  }
  
  fmg_combined_vars = merge(local.fmg1_vars, local.fmg2_vars)
  fmg1_customdata   = base64encode(templatefile("${path.module}/fmg1-customdata.tftpl", local.fmg_combined_vars))
  fmg2_customdata   = base64encode(templatefile("${path.module}/fmg2-customdata.tftpl", local.fmg_combined_vars))
  

  fmg_plan = {
    publisher = "fortinet"
    product   = "fortinet-fortimanager"
    name      = "fortinet-fortimanager"
  }

}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_network_security_group" "fmgnsg" {
  name                = "${var.prefix}-fmg-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "fmgnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowdevregin" {
  name                        = "AllowDevRegInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "541"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowlogsin" {
  name                        = "AllowLogsInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "514"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowremoteaccessin" {
  name                        = "AllowRemoteAccessInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8082"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowhain" {
  name                        = "AllowHAInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 160
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5199"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fmg1pip" {
  name                = "${local.fmg1_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "fmg1", random_string.random.result)
}

resource "azurerm_public_ip" "fmg2pip" {
  name                = "${local.fmg2_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "fmg2", random_string.random.result)
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

resource "azurerm_network_interface" "fmg1ifc" {
  name                 = "${local.fmg1_name}-nic1"
  location             = var.location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fmg1pip.id
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

resource "azurerm_network_interface" "fmg2ifc" {
  name                 = "${local.fmg2_name}-nic1"
  location             = var.location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fmg2pip.id
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

resource "azurerm_network_interface_security_group_association" "fmgnsg" {
  count			    = 2
  network_interface_id      = count.index == 0 ? azurerm_network_interface.fmg1ifc.id : azurerm_network_interface.fmg2ifc.id
  network_security_group_id = azurerm_network_security_group.fmgnsg.id
}

resource "azurerm_linux_virtual_machine" "fmg" {
  count			= 2
  name                  = "${var.prefix}-fmg${count.index+1}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [
    count.index == 0 ? azurerm_network_interface.fmg1ifc.id : azurerm_network_interface.fmg2ifc.id
  ]
  size                  = var.fmg_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_id = var.fmg_source_image_id

  dynamic "source_image_reference" {
    for_each = var.fmg_source_image_id == null ? toset([1]) : toset([])
    content {
      publisher = "fortinet"
      offer     = "fortinet-fortimanager"
      sku       = "fortinet-fortimanager"
      version   = var.fmg_version
    }
  }

  dynamic "plan" {
    for_each = var.fmg_source_image_id == null ? toset([1]) : toset([])
    content {
      publisher = "fortinet"
      product   = "fortinet-fortimanager"
      name      = "fortinet-fortimanager"
    }
  }

  os_disk {
    name                 = "${var.prefix}-fmg${count.index+1}-osdisk"      
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data                     = count.index == 0 ? local.fmg1_customdata : local.fmg2_customdata

  boot_diagnostics {
  }

  tags = var.fortinet_tags

  lifecycle {
    ignore_changes = [custom_data]
  }
}

resource "azurerm_managed_disk" "fmg1-datadisk" {
  count                = var.fmg_datadisk_count
  name                 = "${local.fmg1_name}-datadisk-${count.index+1}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.fmg_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.fmg_datadisk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "fmg1-datadisk-attach" {
  count              = var.fmg_datadisk_count
  managed_disk_id    = element(azurerm_managed_disk.fmg1-datadisk.*.id, count.index)
  virtual_machine_id = azurerm_linux_virtual_machine.fmg[0].id
  lun                = count.index
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "fmg2-datadisk" {
  count                = var.fmg_datadisk_count
  name                 = "${local.fmg2_name}-datadisk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.fmg_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.fmg_datadisk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "fmg2-datadisk-attach" {
  count              = var.fmg_datadisk_count
  managed_disk_id    = element(azurerm_managed_disk.fmg2-datadisk.*.id, count.index)
  virtual_machine_id = azurerm_linux_virtual_machine.fmg[1].id
  lun                = count.index
  caching            = "ReadWrite"
}

resource "azurerm_role_assignment" "network_contributor_fmg1" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_linux_virtual_machine.fmg[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "network_contributor_fmg2" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_linux_virtual_machine.fmg[1].identity[0].principal_id
}


