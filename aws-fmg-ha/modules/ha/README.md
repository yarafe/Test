# FortiManager Single Instance Module

This module deploys a single FortiManager instance on AWS. It is designed to be used with external VPC and subnet resources, which should be created in your example or root configuration, similar to the Azure module structure.

## Features

- Deploys a single FortiManager instance (BYOL or PAYG)
- Minimal required variables: prefix, region, username, password, vpc_id, subnet_id, key_name
- All network infrastructure (VPC, subnet, routing) is handled outside the module
- Only FortiManager-specific resources are managed in the module

## Usage

### Example

```hcl
# In your root or example configuration:

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # ...other VPC settings...
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  # ...other subnet settings...
}

module "fortimanager" {
  source      = "../../modules/single"
  prefix      = var.prefix
  region      = var.region
  vpc_id      = aws_vpc.main.id
  subnet_id   = aws_subnet.main.id
  username    = var.username
  password    = var.password
  key_name    = var.key_name
  fmg_version = var.fmg_version
  fmg_license_type = var.fmg_license_type
  admin_cidr  = var.admin_cidr
  fortigate_cidr = var.fortigate_cidr
  license_file = var.fmg_byol_license_file
  tags        = var.tags
}
```

## Input Variables

| Name           | Description                                      | Type          | Default         | Required |
|----------------|--------------------------------------------------|---------------|-----------------|:--------:|
| prefix         | Prefix added to all deployed resources           | string        | n/a             | yes      |
| region         | AWS region                                       | string        | n/a             | yes      |
| vpc_id         | VPC ID for FortiManager deployment              | string        | n/a             | yes      |
| subnet_id      | Subnet ID for FortiManager deployment           | string        | n/a             | yes      |
| username       | Username for FortiManager admin                 | string        | "admin"         | no       |
| password       | Password for FortiManager admin                 | string        | n/a             | yes      |
| key_name       | AWS key pair name for SSH access                 | string        | n/a             | yes      |
| fmg_version    | FortiManager version for deployment             | string        | "latest"        | no       |
| license_type   | License type (byol or payg)                      | string        | "payg"          | no       |
| create_public_ip | Create and assign a public IP address           | bool          | true            | no       |
| admin_cidr     | CIDR blocks allowed for management access        | list(string)  | ["0.0.0.0/0"]   | no       |
| fortigate_cidr | CIDR blocks for FortiGate log sources            | list(string)  | ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] | no |
| license_file   | License file content for BYOL deployment         | string        | ""              | no       |
| fortinet_tags  | Fortinet specific tags                           | map(string)   | see variables.tf| no       |
| tags           | Additional tags for AWS resources                | map(string)   | {}              | no       |
| root_volume_size | Size of the root volume in GB                   | number        | 100             | no       |
| log_volume_size  | Size of the log volume in GB                    | number        | 100             | no       |
| enable_log_volume| Enable additional volume for log storage        | bool          | true            | no       |

## Outputs

| Name                  | Description                                 |
|-----------------------|---------------------------------------------|
| instance_id           | Instance ID of the FortiManager            |
| private_ip_address    | Private IP address of the FortiManager      |
| public_ip_address     | Public IP address of the FortiManager       |
| security_group_id     | ID of the security group                     |
| deployment_summary    | Deployment information summary               |
| network_interface_id  | ID of the management network interface       |
| log_volume_id         | ID of the log storage volume                 |

## Notes

- All VPC, subnet, and routing resources should be created outside the module (in your example or root configuration).
- Only pass IDs and FortiManager-specific settings to the module.
- This structure matches the Azure module for easier multi-cloud management.

---

For more advanced usage, see the `examples/single` directory.
