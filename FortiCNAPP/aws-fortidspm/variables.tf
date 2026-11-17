# --- Required ---------------------------------------------------------------

variable "region" {
  description = "AWS region the scan engine is deployed in. Set on the aws provider and on every regional resource in the module."
  type        = string
}

# --- FortiCNAPP integration -------------------------------------------------

variable "regions" {
  description = "Every region a scan engine is deployed in, including this one. FortiDSPM issues one token and AMI per entry. Empty = [var.region]."
  type        = list(string)
  default     = []
}

variable "lacework_integration_name" {
  description = "Name of the FortiCNAPP DSPM integration."
  type        = string
  default     = "aws-fortidspm"
}

variable "account_id" {
  description = "AWS account the scan engines belong to. Registered with FortiCNAPP and enforced by the module: terraform refuses to deploy when the caller identity is a different account. Empty = the caller identity's account."
  type        = string
  default     = ""
}

variable "report_deployment_status" {
  description = "Tell FortiDSPM this region's scan engine was created, with its instance id, NAT public IP and IAM role. Sent only after the instance exists; an apply that fails earlier reports nothing."
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Reserved: enable CloudTrail-based activity ingestion for the scan engine. Not yet wired to any resource in the module (no-op placeholder)."
  type        = bool
  default     = false
}

# --- Networking -------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC the module creates. The VPC is isolated (no peering), so the default is fine."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (holds only the NAT gateway). Must be within vpc_cidr."
  type        = string
  default     = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (holds the scan engine instance when enable_public_ip is false). Must be within vpc_cidr."
  type        = string
  default     = "10.0.1.0/24"
}

variable "enable_public_ip" {
  description = "Debugging only. When true, the instance is placed in the public subnet and given a public IP. Outbound then egresses via the instance's own public IP, not the NAT EIP, and S3 reads go via the IGW instead of the S3 gateway endpoint."
  type        = bool
  default     = false
}

variable "office_ip" {
  description = "Source CIDR allowed inbound to TCP 22 and 443 for debugging (for example 203.0.113.4/32). Empty = no inbound rule. Only reachable when enable_public_ip is also true."
  type        = string
  default     = ""
}

# --- Compute and storage ----------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for the scan engine. Empty = the first of m5.2xlarge, m6i.2xlarge, m7i.2xlarge (8 vCPU, 32 GiB, production minimum) that the region offers. When set, must be a Nitro-generation type; c5.xlarge is enough for activation smoke tests."
  type        = string
  default     = ""

  validation {
    condition     = var.instance_type == "" || can(regex("^(c5|m5|r5|c5n|c5d|m5d|r5d|c6i|m6i|r6i|c6a|m6a|r6a|c7i|m7i|r7i|t3|t3a)\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must be a Nitro-generation type (c5/m5/r5/c6i/m6i/r6i/t3/... families). Older Xen-generation types (m4/c4/c3/t2) do not boot the FortiData BYOL AMI correctly."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB. Must be below 10 GiB: the appliance fails to find its boot partition otherwise. Working storage is the separate log volume."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size < 10
    error_message = "root_volume_size must be < 10 GiB."
  }
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "log_volume_size" {
  description = "Size in GiB of the secondary EBS volume used as the appliance's /data log disk. The appliance refuses to boot without it."
  type        = number
  default     = 512
}

# --- Tags -------------------------------------------------------------------

variable "extra_tags" {
  description = "Additional tags applied to all AWS resources created by the module."
  type        = map(string)
  default     = {}
}
