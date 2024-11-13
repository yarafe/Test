##############################################################################################################
#
# FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "prefix" {
  description = "Added name to each deployed resource"
}

variable "location" {
  description = "Azure region"
}

variable "username" {
}

variable "password" {
}

##############################################################################################################
# FortiGate license type
##############################################################################################################

variable "fmg_version" {
  description = "FortiManager version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "fmg_byol_license_file" {
  default = ""
}

variable "fmg_byol_fortiflex_license_token" {
  default = ""
}

variable "fmg_ssh_public_key_file" {
  default = ""
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "fmg_accelerated_networking" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiGate"
  default     = "true"
}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################
provider "azurerm" {
  features {}
}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  description = ""
  default     = "172.16.136.0/22"
}

variable "subnet_prefixes" {
  type        = list(string)
  description = ""

  default = [
    "172.16.136.0/26"   # mgmt
  ]
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "FortiManager-single",
    provider : "6EB3B02F-50E5-4A3E-8CB8-2E1292583FMG"
  }
}

##############################################################################################################
