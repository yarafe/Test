##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
# Main
##############################################################################################################
locals {
  fmg_name = "${var.prefix}-fmg"
  fmg_vars = {
    fmg_vm_name           = "${local.fmg_name}"
    fmg_license_file      = var.fmg_byol_license_file
    fmg_license_fortiflex = var.fmg_byol_fortiflex_license_token
    fmg_username          = var.username
    fmg_ssh_public_key    = var.fmg_ssh_public_key_file
    fmg_ipaddr            = azurerm_network_interface.fmgifc.private_ip_address
    fmg_mask              = cidrnetmask(var.subnet_prefixes[0])
    fmg_gw                = cidrhost(var.subnet_prefixes[0], 1)
  }
  fmg_customdata = base64encode(templatefile("${path.module}/fmg-customdata.tftpl", local.fmg_vars))

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
  name                = "${local.fmg_name}-nsg"
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

resource "azurerm_public_ip" "fmgpip" {
  name                = "${local.fmg_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "fmg", random_string.random.result)
}

resource "azurerm_network_interface" "fmgifc" {
  name                 = "${local.fmg_name}-nic1"
  location             = var.location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fmgpip.id
  }

  lifecycle {
    ignore_changes = [ip_configuration["subnet_id"]]
  }
}

resource "azurerm_network_interface_security_group_association" "fmgnsg" {
  network_interface_id      = azurerm_network_interface.fmgifc.id
  network_security_group_id = azurerm_network_security_group.fmgnsg.id
}

resource "azurerm_linux_virtual_machine" "fmg" {
  name                  = "${local.fmg_name}-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.fmgifc.id]
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
    name                 = "${local.fmg_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data                     = local.fmg_customdata

  boot_diagnostics {
  }

  tags = var.fortinet_tags

  lifecycle {
    ignore_changes = [custom_data]
  }
}

resource "azurerm_managed_disk" "fmg-datadisk" {
  count                = var.fmg_datadisk_count
  name                 = "${local.fmg_name}-datadisk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.fmg_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.fmg_datadisk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "fmg-datadisk-attach" {
  count              = var.fmg_datadisk_count
  managed_disk_id    = element(azurerm_managed_disk.fmg-datadisk.*.id, count.index)
  virtual_machine_id = azurerm_linux_virtual_machine.fmg.id
  lun                = count.index
  caching            = "ReadWrite"
}
