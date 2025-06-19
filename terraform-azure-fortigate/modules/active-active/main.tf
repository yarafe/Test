##############################################################################################################
#
# FortiGate Active/Active High Availability with Azure Standard Load Balancer - External and Internal
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

locals {
  #fgt_name_prefix = "${var.prefix}-fgt"

  #fgt_customdata = {
    #for hostname, vars in var.fgt_customdata_variables :
    #hostname => {
      #hostname   = hostname
      #customdata = base64encode(templatefile("${path.module}/fgt-customdata.tftpl", merge(vars, { hostname = hostname })))
    #}
  #}

  fgt_customdata = {
    for idx, vars in var.fgt_customdata_variables :
    idx => {                                 # Terraform auto-converts numbers to string keys :contentReference[oaicite:0]{index=0}
      hostname   = "${var.prefix}-fgt-${idx}"
      customdata = base64encode(                        # wrap in Base64 for Azure’s custom_data :contentReference[oaicite:1]{index=1}
        templatefile(                                   # render your user-data template with the merged vars :contentReference[oaicite:2]{index=2}
          "${path.module}/fgt-customdata.tftpl",
          merge(vars, { hostname = "${var.prefix}-fgt-${idx}" })
        )
      )
    }
  }

  vm_datadisk_count_map = {
    for fgt_key, data in local.fgt_customdata :
    fgt_key => var.fgt_datadisk_count
  }

  datadisk_lun_map = flatten([
    for fgt_key, count in local.vm_datadisk_count_map : [
      for i in range(count) : {
        fgt_key       = fgt_key
        hostname      = local.fgt_customdata[fgt_key].hostname
        datadisk_name = format(
          "%s-datadisk_%02d",
          local.fgt_customdata[fgt_key].hostname,
          i,
        )
        lun = i
      }
    ]
  ])

  datadisk_attachments = {
    for d in local.datadisk_lun_map :
    d.datadisk_name => d
  }

  lb_pools_ip_addresses = { for lb_pool in flatten([
    for zonek, zonev in var.fgt_ip_configuration : [
      for fgtk, fgtv in zonev : [
        for ipck, ipcv in fgtv : [
          for lbk, lbv in ipcv.load_balancer_backend_pools : {
            name                    = fgtk
            ip_address              = ipcv.private_ip_address
            backend_address_pool_id = lbv.load_balancer_backend_pool_resource_id
            zone_key                = zonek
            ipconfig_key            = ipck
            lb_key                  = lbk
          }
        ]
      ]
    ]
  ]) : "${lb_pool.name}-${lb_pool.zone_key}-${lb_pool.ipconfig_key}-${lb_pool.lb_key}" => lb_pool }
}

resource "azurerm_availability_set" "fgtavset" {
  count               = var.fgt_availability_set ? 1 : 0
  name                = format("%s-availabilityset", var.prefix)
  location            = var.location
  managed             = true
  resource_group_name = var.resource_group_name
}

resource "azurerm_lb_backend_address_pool_address" "fgtaifcext2elbbackendpool" {
  for_each                = local.lb_pools_ip_addresses
  name                    = each.key
  backend_address_pool_id = each.value.backend_address_pool_id
  virtual_network_id      = var.virtual_network_id
  ip_address              = each.value.ip_address
}

resource "azurerm_network_interface" "fgtifcext" {
  for_each            = local.fgt_customdata
  name                = format("%s-nic1-ext", each.value.hostname)
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_forwarding_enabled = true


  dynamic "ip_configuration" {
    for_each = var.fgt_ip_configuration["external"][each.key]
      content {
        name                          = ip_configuration.value.name
        private_ip_address            = ip_configuration.value.private_ip_address == null ? null : ip_configuration.value.private_ip_address
        private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
        private_ip_address_version    = ip_configuration.value.private_ip_address_version
        subnet_id                     = ip_configuration.value.private_ip_subnet_resource_id
        primary                       = ip_configuration.value.is_primary_ipconfiguration
        gateway_load_balancer_frontend_ip_configuration_id = try(ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_resource_id, null)
      }
    }
}



resource "azurerm_network_interface_security_group_association" "fgtaifcextnsg" {
  for_each = local.fgt_customdata
  network_interface_id      = azurerm_network_interface.fgtifcext[each.key].id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
  depends_on = [
    azurerm_network_interface.fgtifcext,
    azurerm_network_security_group.fgtnsg
  ]
}

resource "azurerm_network_interface" "fgtifcint" {
  for_each = local.fgt_customdata
  name     = format("%s-nic2-int", each.value.hostname)
  location = var.location
  resource_group_name = var.resource_group_name
  ip_forwarding_enabled = true

  dynamic "ip_configuration" {
    for_each = var.fgt_ip_configuration["internal"][each.key]
    content {
      name                                               = ip_configuration.value.name
      private_ip_address_allocation                      = ip_configuration.value.private_ip_address_allocation
      gateway_load_balancer_frontend_ip_configuration_id = ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_resource_id
      primary                                            = ip_configuration.value.is_primary_ipconfiguration
      private_ip_address                                 = ip_configuration.value.private_ip_address == null ? null : ip_configuration.value.private_ip_address
      private_ip_address_version                         = ip_configuration.value.private_ip_address_version
      subnet_id                                          = ip_configuration.value.private_ip_subnet_resource_id
    }
  }
}

resource "azurerm_network_interface_security_group_association" "fgtaifcintnsg" {
  for_each = local.fgt_customdata
  network_interface_id      = azurerm_network_interface.fgtifcint[each.key].id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_linux_virtual_machine" "fgtvm" {
  for_each              = local.fgt_customdata
  name                  = each.value.hostname
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.fgtifcext[each.key].id, azurerm_network_interface.fgtifcint[each.key].id]
  size                  = var.fgt_vmsize
  availability_set_id   = var.fgt_availability_set ? azurerm_availability_set.fgtavset[0].id : null
  zone                  = var.fgt_availability_set ? null : var.fgt_availability_zone[0]

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.fgt_image_sku
    version   = var.fgt_version
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.fgt_image_sku
  }

  os_disk {
    name                 = "${each.value.hostname}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                   = var.username
  admin_password                   = var.password
  disable_password_authentication = false
  custom_data                      = each.value.customdata

  dynamic "boot_diagnostics" {
    for_each = var.fgt_serial_console ? [1] : []
    content {}
  }

  tags = var.fortinet_tags

  lifecycle {
    ignore_changes = [custom_data]
  }

  depends_on = [
    azurerm_network_interface_security_group_association.fgtaifcextnsg,
    azurerm_network_interface_security_group_association.fgtaifcintnsg
  ]
}

resource "azurerm_managed_disk" "managed_disk" {
  for_each             = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  name                 = each.key
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.fgt_datadisk_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  for_each = local.datadisk_attachments

  # each.key is the disk‐name you just generated
  managed_disk_id = azurerm_managed_disk.managed_disk[each.key].id

  # look up the VM by the original fgt_key (same index you used to create the VM)
  # assuming your VM resource is for_each = local.fgt_customdata
  virtual_machine_id = azurerm_linux_virtual_machine.fgtvm[each.value.fgt_key].id

  lun     = each.value.lun
  caching = "ReadWrite"
}


#resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  #for_each           = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  #managed_disk_id    = azurerm_managed_disk.managed_disk[each.key].id
  #virtual_machine_id = azurerm_linux_virtual_machine.fgtvm.hostname[each.key].id
  #lun                = lookup(local.luns, each.key)
  #caching            = "ReadWrite"
#}

