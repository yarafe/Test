# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current region
data "aws_region" "current" {}

# Get current caller identity
data "aws_caller_identity" "current" {}

# AMI search for FortiManager BYOL
data "aws_ami" "fortimanager_byol" {
  count       = var.fmg_license_type == "byol" ? 1 : 0
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["FortiManager-VM64-AWS *${var.fmg_version}*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# AMI search for FortiManager PAYG
data "aws_ami" "fortimanager_payg" {
  count       = var.fmg_license_type == "payg" ? 1 : 0
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["FortiManager-VM64-AWSONDEMAND*${var.fmg_version}*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get VPC information
# data "aws_vpc" "selected" {
#   count = var.vpc_id != "" ? 1 : 0
#   id    = var.vpc_id
# }

# Get subnet information
# data "aws_subnet" "selected" {
#   count = var.subnet_id != "" ? 1 : 0
#   id    = var.subnet_id
# }
# 