##############################################################################################################
#
# FortiAnalyzer - High Availability Active/Passive
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

data "azurerm_subscription" "current" {}

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
  subnet_names        = ["${var.prefix}-subnet-fortianalyzer"]
  vnet_name           = "${var.prefix}-vnet"
  vnet_location       = var.location

  tags = var.fortinet_tags
}

##############################################################################################################
# FortiAnalyzer   
##############################################################################################################
module "faz-ha" {
  source = "../modules/HA"

  prefix                           	= var.prefix
  location                         	= var.location
  resource_group_name              	= azurerm_resource_group.resourcegroup.name 
  subscription_id					          = data.azurerm_subscription.current.subscription_id
  username                         	= var.username
  password                         	= var.password
  faz_version                      	= var.faz_version
  faz1_byol_license_file            = var.faz1_byol_license_file
  faz1_byol_fortiflex_license_token = var.faz1_byol_fortiflex_license_token
  faz1_byol_serial_number			      = var.faz1_byol_serial_number
  faz2_byol_license_file            = var.faz2_byol_license_file
  faz2_byol_fortiflex_license_token = var.faz2_byol_fortiflex_license_token
  faz2_byol_serial_number			      = var.faz2_byol_serial_number
  faz_accelerated_networking        = var.faz_accelerated_networking
  ha_ip		  		                    = var.ha_ip
  subnet_id          				        = module.vnet.vnet_subnets[0]
  virtual_network_id 				        = module.vnet.vnet_id
  subnet_prefixes     				      = var.subnet_prefixes 
  depends_on = [
    module.vnet
  ]

}


##############################################################################################################
