output "instance_id" {
  description = "Instance ID of the FortiManager"
  value       = aws_instance.fortimanager.id
}

output "private_ip_address" {
  description = "Private IP address of the FortiManager"
  value       = aws_instance.fortimanager.private_ip
}

output "public_ip_address" {
  description = "Public IP address of the FortiManager"
  value       = try(aws_eip.fortimanager[0].public_ip, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.fortimanager.id
}

output "deployment_summary" {
  description = "Deployment information summary"
  value = templatefile("${path.module}/templates/summary.tpl", {
    region                = var.region
    fmg_username         = var.username
    public_ip_address    = try(aws_eip.fortimanager[0].public_ip, "N/A")
    private_ip_address   = aws_instance.fortimanager.private_ip
  })
}

# Network interface information
output "network_interface_id" {
  description = "ID of the management network interface"
  value       = aws_network_interface.fortimanager_mgmt.id
}

# Volume information
output "log_volume_id" {
  description = "ID of the log storage volume"
  value       = var.enable_log_volume ? aws_ebs_volume.fortimanager_logs[0].id : null
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

output "availability_zone" {
  description = "Availability zone where FortiManager is deployed"
  value       = aws_instance.fortimanager.availability_zone
}
