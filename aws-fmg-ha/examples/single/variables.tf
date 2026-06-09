##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
# Terraform deployment template for AWS
#
##############################################################################################################

# Basic configuration
variable "prefix" {
  description = "Prefix for all deployed resources"
  type        = string
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "username" {
  description = "FortiManager admin username"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "FortiManager admin password"
  type        = string
  sensitive   = true
}

# Network configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for deployment"
  type        = string
  default     = "us-west-2a"
}

# FortiManager configuration
variable "fmg_vmsize" {
  description = "EC2 instance type for FortiManager"
  type        = string
  default     = "m5.xlarge"
}

variable "fmg_license_type" {
  description = "License type (byol or payg)"
  type        = string
  default     = "payg"

  validation {
    condition     = contains(["byol", "payg"], var.fmg_license_type)
    error_message = "License type must be either 'byol' or 'payg'."
  }
}

variable "fmg_version" {
  description = "FortiManager version"
  type        = string
  default     = "latest"
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR blocks allowed for management access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "fmg_byol_license_file" {
  description = "License file content for BYOL deployment"
  type        = string
  default     = ""
}

variable "fmg_byol_fortiflex_license_token" {
  description = "FortiFlex license token content for BYOL deployment"
  type        = string
  default     = ""
}

variable "fmg_ssh_public_key_file" {
  description = "SSH public key file for FortiManager access"
  type        = string
  default     = ""
}

# Tags
variable "fortinet_tags" {
  description = "Fortinet specific tags"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "FortiManager-Single"
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}

# IAM
variable "create_iam_role" {
  description = "Create IAM role for FortiManager"
  type        = bool
  default     = true
}