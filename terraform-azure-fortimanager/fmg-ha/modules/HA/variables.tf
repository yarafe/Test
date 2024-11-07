##############################################################################################################
#
# FortiManager - High Availability  FortiManager VM-A
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
# Variables
##############################################################################################################

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
# Names and data sources of linked Azure resource
##############################################################################################################

variable "resource_group_name" {
}

variable "virtual_network_id" {
  description = "Id of the VNET to deploy the FortiManager into"
}

variable "subnet_id" {
  description = ""
}

variable "subnet_prefixes" {
  description = ""
}

##############################################################################################################
# FortiManager
##############################################################################################################

variable "fmg_version" {
  description = "FortiManager version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "fmg1_byol_license_file" {
  default = ""
}

variable "fmg1_byol_fortiflex_license_token" {
  default = ""
}

variable "fmg1_byol_serial_number" {
  description = "FMG1 Serial Number is required for FMG-HA deployment"
  default = ""
}

variable "fmg2_byol_license_file" {
  default = ""
}

variable "fmg2_byol_fortiflex_license_token" {
  default = ""
}

variable "fmg2_byol_serial_number" {
  description = "FMG2 Serial Number is required for FMG-HA deployment"
  default = ""
}

variable "fmg_ssh_public_key_file" {
  default = ""
}

variable "fmg_vmsize" {
  default = "Standard_D2s_v3"
}

variable "fmg_datadisk_size_gb" {
  default = 50
}

variable "fmg_storage_account_type" {
  default = "Standard_LRS"
}

variable "fmg_datadisk_count" {
  default = 1
}

variable "fmg_accelerated_networking" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiManager"
  default     = "true"
}

variable "fmg_source_image_id" {
  description = "Reference a your own FortiManager image instead of one from the Azure Marketplace"
  default     = null
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "FortiManager-HA",
    provider : "6EB3B02F-50E5-4A3E-8CB8-2E1292583FMG"
  }
}

##############################################################################################################
