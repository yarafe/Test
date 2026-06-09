##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
# Terraform deployment template for AWS
#
##############################################################################################################

output "fortimanager_public_ip" {
  description = "Public IP address of the FortiManager instance"
  value       = module.fortimanager.public_ip_address
}

output "fortimanager_private_ip" {
  description = "Private IP address of the FortiManager instance"
  value       = module.fortimanager.private_ip_address
}

output "fortimanager_id" {
  description = "Instance ID of the FortiManager"
  value       = module.fortimanager.instance_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.fortimanager.security_group_id
}
