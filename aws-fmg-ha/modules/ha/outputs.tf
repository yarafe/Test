##############################################################################################################
#
# FortiManager - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################

output "fmg1_instance_id" {
  description = "Instance ID of the FortiManager"
  value       = aws_instance.fmg1.id
}

output "fmg2_instance_id" {
  description = "Instance ID of the FortiManager"
  value       = aws_instance.fmg2.id
}
output "vip_public_ip_address" {
  description = "Public IP address of the FortiManager"
  value       = try(aws_eip.vip[0].public_ip, null)
}

output "fmg1_public_ip_address" {
  description = "Public IP address of the FortiManager"
  value       = try(aws_eip.fmg1[0].public_ip, null)
}

output "fmg2_public_ip_address" {
  description = "Public IP address of the FortiManager"
  value       = try(aws_eip.fmg2[0].public_ip, null)
}

output "fmg1_private_ip_address" {
  description = "Private IP address of the FortiManager"
  value       = aws_instance.fmg1.private_ip
}

output "fmg2_private_ip_address" {
  description = "Private IP address of the FortiManager"
  value       = aws_instance.fmg2.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.fortimanager.id
}

output "deployment_summary" {
  description = "Deployment information summary"
  value = templatefile("${path.module}/templates/summary.tpl", {
    region                  = var.region
    fmg1_public_ip_address  = try(aws_eip.fmg1[0].public_ip, "N/A")
    fmg2_public_ip_address  = try(aws_eip.fmg2[0].public_ip, "N/A")
    fmg1_private_ip_address = aws_instance.fmg1.private_ip
    fmg2_private_ip_address = aws_instance.fmg2.private_ip
    fmg1_instance_id       = aws_instance.fmg1.id
    fmg2_instance_id       = aws_instance.fmg2.id
    vip_public_ip_address  = try(aws_eip.vip[0].public_ip, "N/A")
  })
}

# Network interface information
output "network_interface_id" {
  description = "ID of the management network interface"
  value       = aws_network_interface.fmg1.id
}

# Volume information
output "log_volume_id" {
  description = "ID of the log storage volume"
  value       = var.enable_log_volume ? aws_ebs_volume.fmg1_logs[0].id : null
}

# IAM information
output "iam_role_arn" {
  description = "ARN of the FortiManager IAM role"
  value       = var.create_iam_role ? aws_iam_role.fortimanager[0].arn : null
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = var.create_iam_role ? aws_iam_instance_profile.fortimanager[0].name : null
}

# AMI information
output "ami_id" {
  description = "AMI ID used for the FortiManager instance"
  value       = local.ami_id
}

output "ami_name" {
  description = "Name of the AMI used"
  value = var.fmg_license_type == "byol" ? (
    length(data.aws_ami.fortimanager_byol) > 0 ? data.aws_ami.fortimanager_byol[0].name : null
    ) : (
    length(data.aws_ami.fortimanager_payg) > 0 ? data.aws_ami.fortimanager_payg[0].name : null
  )
}

# Deployment information
output "fmg_license_type" {
  description = "License type used for deployment"
  value       = var.fmg_license_type
}

output "fortimanager_version" {
  description = "FortiManager version deployed"
  value       = var.fmg_version
}

output "fmg1_availability_zone" {
  description = "Availability zone where FortiManager is deployed"
  value       = aws_instance.fmg1.availability_zone
}

output "fmg2_availability_zone" {
  description = "Availability zone where FortiManager is deployed"
  value       = aws_instance.fmg2.availability_zone
}
