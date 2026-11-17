output "instance_id" {
  description = "EC2 instance ID running the scan engine. Reference this when contacting Fortinet support."
  value       = module.fortidspm.instance_id
}

output "private_ip" {
  description = "Private IP of the scan engine EC2 instance."
  value       = module.fortidspm.private_ip
}

output "public_ip" {
  description = "Public IP of the scan engine instance. Empty when enable_public_ip = false."
  value       = module.fortidspm.public_ip
}

output "vpc_id" {
  description = "ID of the VPC the module created."
  value       = module.fortidspm.vpc_id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT gateway, the source IP of all scan engine outbound traffic. Give it to Fortinet if an egress allowlist is needed."
  value       = module.fortidspm.nat_gateway_public_ip
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the scan engine."
  value       = module.fortidspm.iam_role_arn
}

output "iam_role_name" {
  description = "IAM role name, useful to attach extra policies."
  value       = module.fortidspm.iam_role_name
}

output "security_group_id" {
  description = "Security group ID controlling scan engine egress."
  value       = module.fortidspm.security_group_id
}

output "lacework_integration_guid" {
  description = "GUID of the FortiCNAPP DSPM integration."
  value       = module.fortidspm.lacework_integration_guid
}

output "deployment_id" {
  description = "FortiDSPM deployment id."
  value       = module.fortidspm.deployment_id
}

output "deployment_name" {
  description = "FortiDSPM deployment name."
  value       = module.fortidspm.deployment_name
}

output "env_id" {
  description = "FortiDSPM environment id."
  value       = module.fortidspm.env_id
}

output "activation_tokens" {
  description = "Single-use activation token per region, issued by FortiDSPM."
  value       = module.fortidspm.activation_tokens
  sensitive   = true
}

output "image_ids" {
  description = "Scan engine AMI per region, issued by FortiDSPM."
  value       = module.fortidspm.image_ids
}
