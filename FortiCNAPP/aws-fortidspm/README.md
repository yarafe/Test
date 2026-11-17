# FortiDSPM scan engine on AWS

## Introduction

Deploys one FortiDSPM scan engine into a single AWS region using the `lacework/fortidspm/aws` module. The module builds an isolated VPC (public subnet with a NAT gateway, private subnet for the instance, S3 gateway endpoint), an IAM role, an egress-only security group and the scan engine EC2 appliance. It also registers the AWS account with FortiCNAPP as a DSPM integration.

## Prerequisites

- Terraform `>= 1.2`.
- Providers: `hashicorp/aws ~> 6.0` and `lacework/lacework >= 2.6.0`.
- AWS credentials for the target account. They need permission to create VPC, EC2, IAM and EIP resources, and `ec2:DescribeInstanceTypeOfferings` (used to pick the instance type and AZ at plan time).
- FortiCNAPP API credentials in the environment: `LW_ACCOUNT`, `LW_API_KEY`, `LW_API_SECRET`, and `LW_SUBACCOUNT` for organization accounts.
- Capacity for an `m5.2xlarge`, `m6i.2xlarge` or `m7i.2xlarge` (8 vCPU, 32 GiB) in the chosen region, unless you set `instance_type`.
- Outbound internet from the NAT gateway to Fortinet's control plane. Allow `nat_gateway_public_ip` if egress is filtered.

## Deployment

Edit `terraform.tfvars` (at minimum `region`), then:

```bash
export LW_ACCOUNT="<account>" LW_API_KEY="<key>" LW_API_SECRET="<secret>"

terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
terraform destroy -var-file=terraform.tfvars   # removes the scan engine and the FortiCNAPP integration
```

Notes:

- Names are deterministic. Deploying the same deployment into the same account twice fails on the duplicate IAM role.
- The activation token is single-use. To rebuild the instance, taint the module's `lacework_integration_aws_fortidspm` resource and apply again.
- This root uses `global = true`, so it is one complete deployment. For several regions, add one module instance per region and point the extra instances at the global one with `global_module_reference` (see the module's `examples/multi-region`).

## Use case

A security team wants FortiCNAPP to discover and classify sensitive data in S3 buckets of one AWS account. The scan engine runs inside that account, reads the buckets through its IAM role, and sends results to FortiCNAPP without any inbound access.

## References

- Module on the Terraform Registry: <https://registry.terraform.io/modules/lacework/fortidspm/aws/latest>
- Module source and examples: <https://github.com/lacework/terraform-aws-fortidspm>
