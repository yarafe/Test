##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.prefix}-rg"
  location = var.location

  lifecycle {
    ignore_changes = [tags["CreatedOnDate"]]
  }
}

##############################################################################################################
# Virtual Network - VNET
##############################################################################################################
module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "4.1.0"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  use_for_each        = true
  address_space       = [var.vnet]
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = ["${var.prefix}-subnet-fortimanager"]
  vnet_name           = "${var.prefix}-vnet"
  vnet_location       = var.location

  tags = var.fortinet_tags
}

##############################################################################################################
# FortiManager   virtual_network_name             = module.vnet.vnet_name
#  subnet_name                      = keys(module.vnet.vnet_subnets_name_id)[0]
##############################################################################################################
module "fmg" {
  source = "../modules/single"

  prefix                           = var.prefix
  location                         = var.location
  resource_group_name              = azurerm_resource_group.resourcegroup.name
  username                         = var.username
  password                         = var.password
  fmg_version                      = var.fmg_version
  fmg_byol_license_file            = var.fmg_byol_license_file
  fmg_byol_fortiflex_license_token = var.fmg_byol_fortiflex_license_token
  fmg_accelerated_networking       = var.fmg_accelerated_networking
  subnet_id                        = module.vnet.vnet_subnets[0]
  virtual_network_id               = module.vnet.vnet_id
  subnet_prefixes                  = var.subnet_prefixes 
  depends_on = [
    module.vnet
  ]

}

##############################################################################################################
