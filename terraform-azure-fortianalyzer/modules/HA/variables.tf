##############################################################################################################
#
# Fortianalyzer - High Availability  Fortianalyzer VM
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

variable "ha_ip" {
  description = "ha_ip: either 'public' or 'private'"
  type        = string

  validation {
    condition     = var.ha_ip == "public" || var.ha_ip == "private"
    error_message = "The ha_ip variable must be either 'public' or 'private'."
  }
}


##############################################################################################################
# Names and data sources of linked Azure resource
##############################################################################################################

variable "resource_group_name" {
}

variable "virtual_network_id" {
  description = "Id of the VNET to deploy the Fortianalyzer into"
}

variable "subnet_id" {
  description = ""
}

variable "subnet_prefixes" {
  description = ""
}

##############################################################################################################
# Fortianalyzer
##############################################################################################################

variable "faz_version" {
  description = "Fortianalyzer version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "7.4.0"
}

variable "faz1_byol_license_file" {
  default = ""
}

variable "faz1_byol_fortiflex_license_token" {
  default = ""
}

variable "faz1_byol_serial_number" {
  description = "FMG1 Serial Number is required for FMG-HA deployment"
  default = ""
}

variable "faz2_byol_license_file" {
  default = ""
}

variable "faz2_byol_fortiflex_license_token" {
  default = ""
}

variable "faz2_byol_serial_number" {
  description = "FMG2 Serial Number is required for FMG-HA deployment"
  default = ""
}

variable "faz_ssh_public_key_file" {
  default = ""
}

variable "faz_vmsize" {
  default = "Standard_D2s_v3"
}

variable "faz_datadisk_size_gb" {
  default = 50
}

variable "faz_storage_account_type" {
  default = "Standard_LRS"
}

variable "faz_datadisk_count" {
  default = 1
}

variable "faz_accelerated_networking" {
  description = "Enables Accelerated Networking for the network interfaces of the Fortianalyzer"
  default     = "true"
}

variable "faz_source_image_id" {
  description = "Reference a your own Fortianalyzer image instead of one from the Azure Marketplace"
  default     = null
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "Fortianalyzer-HA",
    provider : "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}

##############################################################################################################
