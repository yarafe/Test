##############################################################################################################
#
# FortiAnalyzer Active/Passive High Availability 
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

variable "ha_ip" {
  description = "ha_ip: either 'public' or 'private'"
  type        = string

  validation {
    condition     = var.ha_ip == "public" || var.ha_ip == "private"
    error_message = "The ha_ip variable must be either 'public' or 'private'."
  }
}

##############################################################################################################
# FortiAnalyzer license type
##############################################################################################################

variable "faz_version" {
  description = "FortiAnalyzer version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "faz1_byol_license_file" {
  default = ""
}

variable "faz1_byol_fortiflex_license_token" {
  default = ""
}

variable "faz1_byol_serial_number" {
  description = "FAZ1 Serial Number is required for FAZ-HA deployment"
  default = ""
}

variable "faz2_byol_license_file" {
  default = ""
}

variable "faz2_byol_fortiflex_license_token" {
  default = ""
}

variable "faz2_byol_serial_number" {
  description = "FAZ2 Serial Number is required for FAZ-HA deployment"
  default = ""
}

variable "faz_ssh_public_key_file" {
  default = ""
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "faz_accelerated_networking" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiAnalyzer"
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
    template : "FortiAnalyzer-HA",
    provider : "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}

##############################################################################################################
