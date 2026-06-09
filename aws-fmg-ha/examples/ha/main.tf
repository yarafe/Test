##############################################################################################################
#
# FortiManager - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################

##############################################################################################################
# Networking
##############################################################################################################
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-igw"
  })
}

resource "aws_subnet" "subnets" {
  for_each = { for s in var.subnets : s.name => s }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-${each.key}"
  })
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-rt"
  })
}

resource "aws_route_table_association" "rt_subnet1" {
  for_each = aws_subnet.subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# FortiManager Module
module "fortimanager" {
  source = "../../modules/ha"

  prefix                            = var.prefix
  region                            = var.region
  vpc_id                            = aws_vpc.vpc.id
  subnet_ids                        = var.ha_ip == "public" ? [aws_subnet.subnets[var.subnets[0].name].id,aws_subnet.subnets[var.subnets[1].name].id] : [aws_subnet.subnets[var.subnets[0].name].id]
  subnet_availability_zones         = var.ha_ip == "public" ? [aws_subnet.subnets[var.subnets[0].name].availability_zone,aws_subnet.subnets[var.subnets[1].name].availability_zone] : [aws_subnet.subnets[var.subnets[0].name].availability_zone]
  key_name                          = var.key_name
  fmg_version                       = var.fmg_version
  fmg_vmsize                        = var.fmg_vmsize
  fmg_license_type                  = var.fmg_license_type
  admin_cidr                        = var.admin_cidr
  fortigate_cidr                    = var.fortigate_cidr
  fmg1_byol_license_file            = var.fmg1_byol_license_file
  fmg1_byol_fortiflex_license_token = var.fmg1_byol_fortiflex_license_token
  fmg2_byol_license_file            = var.fmg2_byol_license_file
  fmg2_byol_fortiflex_license_token = var.fmg2_byol_fortiflex_license_token
  fmg1_byol_serial_number           = var.fmg1_byol_serial_number
  fmg2_byol_serial_number           = var.fmg2_byol_serial_number
  ha_ip                             = var.ha_ip
  ha_password                       = var.ha_password
  create_iam_role                   = var.create_iam_role
}
