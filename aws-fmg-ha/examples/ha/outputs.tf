##############################################################################################################
#
# FortiManager - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################

output "vip_public_ip" {
  description = "Public IP address of the FortiManager VIP instance"
  value       = module.fortimanager.vip_public_ip_address
}

output "fmg1_public_ip" {
  description = "Public IP address of the FortiManager instance"
  value       = module.fortimanager.fmg1_public_ip_address
}

output "fmg1_private_ip_address" {
  description = "Private IP address of the FortiManager instance"
  value       = module.fortimanager.fmg1_private_ip_address
}

output "fmg2_public_ip" {
  description = "Public IP address of the FortiManager instance"
  value       = module.fortimanager.fmg2_public_ip_address
}

output "fmg2_private_ip_address" {
  description = "Private IP address of the FortiManager instance"
  value       = module.fortimanager.fmg2_private_ip_address
}

output "fmg1_instance_id" {
  description = "Instance ID of the FortiManager"
  value       = module.fortimanager.fmg1_instance_id
}

output "fmg2_instance_id" {
  description = "Instance ID of the FortiManager"
  value       = module.fortimanager.fmg2_instance_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.fortimanager.security_group_id
}

output "deployment_summary" {
  description = "Deployment information summary"
  value       = module.fortimanager.deployment_summary
}
