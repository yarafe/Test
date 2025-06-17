##############################################################################################################
#
# FortiGate Active/Active High Availability with Azure Standard Load Balancer - External and Internal
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

##############################################################################################################
# Resource Group
##############################################################################################################
resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.prefix}-rg"
  location = var.location
}

##############################################################################################################
# Virtual Network - VNET
##############################################################################################################
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = var.vnet
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnets" {
  for_each = { for s in var.subnets : s.name => s }

  name                 = each.key
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.cidr
}

##############################################################################################################
# Load Balancers
##############################################################################################################

locals {
  # produce a sequence [0,1,…,fgt_count-1]
  fgt_indices = range(var.fgt_count)

  # build a flat list of objects, two per VM:
  fgt_nat_rules = flatten([
    for i in local.fgt_indices : [
      {
        fgt_index      = i
        name          = "${var.prefix}-fgt-${i+1}-MGMT-HTTPS"
        protocol      = "Tcp"
        frontend_port = 40030 + i
        backend_port  = 443
      },
      {
        fgt_index      = i
        name          = "${var.prefix}-fgt-${i+1}-MGMT-SSH"
        protocol      = "Tcp"
        frontend_port = 50030 + i
        backend_port  = 22
      }
    ]
  ])

  # turn that list into a map keyed by rule-name
  fgt_nat_rules_map = {
    for r in local.fgt_nat_rules : r.name => r
  }
}

# Create the NAT‐rules on your external LB
resource "azurerm_lb_nat_rule" "elbinboundrules" {
  depends_on = [module.fgt.fortigate_network_interface_external]
  for_each = local.fgt_nat_rules_map

  name                           = each.key
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = module.elb.azurerm_lb_id
  frontend_ip_configuration_name = module.fgt.fortigate_network_interface_external[(each.value.fgt_index)].ip_configuration.value.name

  protocol                    = each.value.protocol
  frontend_port               = each.value.frontend_port
  backend_port                = each.value.backend_port

  enable_floating_ip          = false
  idle_timeout_in_minutes     = 4
  enable_tcp_reset            = false
}

module "elb" {
  source                       = "Azure/loadbalancer/azurerm"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  name                         = "${var.prefix}-externalloadbalancer"
  type                         = "public"
  lb_floating_ip_enabled       = true
  lb_probe_interval            = 5
  lb_probe_unhealthy_threshold = 2
  lb_sku                       = "Standard"
  pip_name                     = "${var.prefix}-elb-pip"
  pip_sku                      = "Standard"

  lb_port = {
    http     = ["80", "Tcp", "80"]
    udp10551 = ["10551", "Udp", "10551"]
  }
  lb_probe = {
    lbprobe = ["Tcp", "8008", ""]
  }

  tags       = var.fortinet_tags
  depends_on = [azurerm_resource_group.resourcegroup]
}

module "ilb" {
  source                       = "Azure/loadbalancer/azurerm"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  name                         = "${var.prefix}-internalloadbalancer"
  type                         = "private"
  lb_floating_ip_enabled       = true
  lb_probe_interval            = 5
  lb_probe_unhealthy_threshold = 2
  lb_sku                       = "Standard"
  frontend_subnet_id           = azurerm_subnet.subnets["subnet-internal"].id

  lb_port = {
    haports = ["0", "All", "0"]
  }
  lb_probe = {
    lbprobe = ["Tcp", "8008", ""]
  }
  tags       = var.fortinet_tags
  depends_on = [azurerm_resource_group.resourcegroup]
}

##############################################################################################################
# Public IP for management interface of the FortiGate
##############################################################################################################
#resource "azurerm_public_ip" "fgtamgmtpip" {
#  name                = "${var.prefix}-fgt-a-mgmt-pip"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.resourcegroup.name
#  allocation_method   = "Static"
#  domain_name_label   = "${var.prefix}-fgt-a-mgmt-pip"
#  sku                 = "Standard"
#}

#resource "azurerm_public_ip" "fgtbmgmtpip" {
#  name                = "${var.prefix}-fgt-b-mgmt-pip"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.resourcegroup.name
#  allocation_method   = "Static"
#  domain_name_label   = "${var.prefix}-fgt-b-mgmt-pip"
#  sku                 = "Standard"
#}


##############################################################################################################
# FortiGate
##############################################################################################################

module "fgt" {
  source                             = "../../modules/active-active"
  prefix                             = var.prefix
  location                           = var.location
  resource_group_name                = azurerm_resource_group.resourcegroup.name
  username                           = var.username
  password                           = var.password
  virtual_network_id                 = azurerm_virtual_network.vnet.id
  virtual_network_address_space      = azurerm_virtual_network.vnet.address_space
  subnet_names                       = slice([for s in var.subnets : s.name], 0, 2)
  fgt_count                          = 2
  fgt_image_sku                      = var.fgt_image_sku
  fgt_version                        = var.fgt_version
  fgt_accelerated_networking         = var.fgt_accelerated_networking
  fgt_ip_configuration               = local.fgt_ip_configuration
  fgt_availability_set               = true
  fgt_availability_zone              = []
  fgt_datadisk_size                  = var.fgt_datadisk_size
  fgt_datadisk_count                 = var.fgt_datadisk_count
  fgt_serial_console                 = var.fgt_serial_console
  fortinet_tags                      = var.fortinet_tags
  fgt_customdata_variables           = local.fgt_vars
  subscription_id                    = var.subscription_id
}

##############################################################################################################
