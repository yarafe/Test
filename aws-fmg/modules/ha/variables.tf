##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
# Terraform deployment template for AWS
#
##############################################################################################################
# Variables
##############################################################################################################

variable "prefix" {
  description = "Prefix added to all deployed resources"
  type        = string
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
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
# Network Configuration
##############################################################################################################

variable "vpc_id" {
  description = "VPC ID for FortiManager deployment"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for FortiManager VMs. Provide 1 subnet for private HA or 2 subnets for public HA."

  validation {
    condition = (
      (var.ha_ip != "public" && length(var.subnet_ids) == 1) ||
      (var.ha_ip == "public" && length(var.subnet_ids) == 2)
    )
    error_message = "Private HA requires 1 subnet ID; public HA requires exactly 2 subnet IDs."
  }
}

variable "subnet_availability_zones" {
  type        = list(string)
  description = "AZs for FortiManager subnets. Provide 1 AZ for private HA or 2 AZs for public HA."

  validation {
    condition = (
      (var.ha_ip != "public" && length(var.subnet_availability_zones) == 1) ||
      (var.ha_ip == "public" && length(var.subnet_availability_zones) == 2)
    )
    error_message = "Private HA requires 1 AZ; public HA requires exactly 2 AZs."
  }
}

##############################################################################################################
# FortiManager Specific Configuration
##############################################################################################################

variable "fmg_version" {
  description = "FortiManager version for deployment"
  type        = string
  default     = "latest"
}

variable "fmg_vmsize" {
  description = "EC2 instance type for FortiManager"
  type        = string
  default     = "m5.xlarge"
}

variable "fmg_license_type" {
  description = "License type for FortiManager deployment (byol or payg)"
  type        = string
  default     = "payg"

  validation {
    condition     = contains(["byol", "payg"], var.fmg_license_type)
    error_message = "License type must be either 'byol' or 'payg'."
  }
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
  default     = ""
}

variable "create_public_ip" {
  description = "Create and assign a public IP address"
  type        = bool
  default     = true
}

variable "admin_cidr" {
  description = "CIDR blocks allowed for FortiManager management access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "fortigate_cidr" {
  description = "CIDR blocks for FortiGate log sources"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# FortiManager HA Configuration
variable "ha_password" {
  description = "Password for FortiManager HA"
  type        = string
  sensitive   = true
}

variable "fmg1_byol_serial_number" {
  description = "Serial number of FortiManager unit 1 for HA peer configuration"
  type        = string
  default     = ""
}

variable "fmg2_byol_serial_number" {
  description = "Serial number of FortiManager unit 2 for HA peer configuration"
  type        = string
  default     = ""
}

# FortiManager license configuration
variable "fmg1_byol_license_file" {
  description = "License file content for BYOL deployment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fmg1_byol_fortiflex_license_token" {
  description = "FortiFlex license token content for BYOL deployment"
  type        = string
  default     = ""
}

variable "fmg2_byol_license_file" {
  description = "License file content for BYOL deployment"
  type        = string
  default     = ""
}

variable "fmg2_byol_fortiflex_license_token" {
  description = "FortiFlex license token content for BYOL deployment"
  type        = string
  default     = ""
}

##############################################################################################################
# Storage Configuration
##############################################################################################################

variable "fmg_root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 100
}

variable "fmg_log_volume_size" {
  description = "Size of the log volume in GB"
  type        = number
  default     = 500
}

variable "fmg_log_volume_type" {
  description = "Type of the log volume"
  type        = string
  default     = "gp3"
}

variable "enable_log_volume" {
  description = "Enable additional volume for log storage"
  type        = bool
  default     = true
}

##############################################################################################################
# Additional Configuration
##############################################################################################################

variable "fmg_admin_port" {
  description = "Admin port for FortiManager management interface"
  type        = number
  default     = 443
}

variable "create_iam_role" {
  description = "Create IAM role for FortiManager"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "enable_termination_protection" {
  description = "Enable EC2 termination protection"
  type        = bool
  default     = false
}

variable "fortinet_tags" {
  description = "Fortinet specific tags"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "FortiManager-HA"
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FMG"
  }
}
