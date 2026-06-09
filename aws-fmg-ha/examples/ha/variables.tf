##############################################################################################################
#
# FortiManager - High Availability Deployment
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
  default     = "eu-north-1"
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
# Deployment in AWS
##############################################################################################################
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

##############################################################################################################
# Network Configuration
##############################################################################################################

variable "vpc" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
    availability_zone = string
  }))
  description = ""

  default = [
    { name = "subnet-fmg1", cidr = "172.16.136.0/26", availability_zone = "eu-north-1a" },  # FortiManager 1
    { name = "subnet-fmg2", cidr = "172.16.136.64/26", availability_zone = "eu-north-1b" }, # FortiManager 2
  ]
}

##############################################################################################################
# FortiManager Specific Configuration
##############################################################################################################

variable "fmg_version" {
  description = "FortiManager version"
  type        = string
  default     = "7.6.6"
}

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

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR blocks allowed for management access"
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

# FortiManager Additional Configuration
variable "create_iam_role" {
  description = "Create IAM role for FortiManager"
  type        = bool
  default     = true
}

# Tags
variable "fortinet_tags" {
  description = "Fortinet specific tags"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "FortiManager-HA"
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FMG"
  }
}
