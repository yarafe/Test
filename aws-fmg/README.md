# FortiManager Terraform modules for AWS

:wave: - [Introduction](#introduction) - [Architecture & Design](#architecture--design) - [Deployment](#deployment) - [Support](#support) - :wave:

## Introduction

This repository provides Terraform modules for deploying Fortinet FortiManager on AWS. FortiManager delivers centralized management of Fortinet devices — configuration, policy and object management, device provisioning, and firmware control — across an environment.

Two deployment patterns are available, each with a reusable module and a ready-to-run example:

- **Single** — one standalone FortiManager instance.
- **HA** — an active-passive pair with VRRP-based automatic failover.

Both patterns support **BYOL** and **PAYG** licensing, and automatically discover the latest matching Marketplace AMI for the chosen license type and version.

## Architecture & Design

| Pattern | Use when | Failover | Detailed docs |
|---------|----------|----------|---------------|
| **Single** | Labs, PoCs, and non-critical or cost-sensitive deployments | None | [`examples/single/README.md`](examples/single/README.md) |
| **HA** | Production deployments that need continuous management availability | VRRP active-passive | [`examples/ha/README.md`](examples/ha/README.md) |

The **single** module provisions one EC2 instance on a management ENI, with an optional Elastic IP and an optional encrypted log volume.

The **HA** module deploys two nodes in an active-passive cluster and supports two topologies, both using VRRP for automatic failover:

- **Public VIP** — nodes in separate subnets/AZs (cross-AZ resilience); public VIP moves to the active node on failover.
- **Private VIP** — both nodes in one subnet/AZ; secondary private IP moves between nodes. Public IPs on the nodes are optional.

The HA README documents both topologies, the resulting CLI HA configuration, and failover behavior in detail.

## Repository Structure

```text
terraform-aws-fortimanager/
├── modules/
│   ├── single/                  # Single FortiManager deployment module
│   └── ha/                      # HA (active-passive, VRRP) deployment module
├── examples/
│   ├── single/                  # Single example
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   │   └── README.md
│   └── ha/                      # HA example
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
│       └── README.md
└── README.md
```

## Deployment

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 and AWS provider >= 5.0
- An existing VPC and subnet(s)
- AWS key pair for SSH access
- For BYOL: a valid FortiManager license file or FortiFlex token
- [FortiManager supported instance types](https://docs.fortinet.com/document/fortimanager-public-cloud/8.0.0/aws-administration-guide/351055/instance-type-support)
- [FortiManager requires a minimum disk size of 500 GB](https://docs.fortinet.com/document/fortimanager-public-cloud/8.0.0/aws-administration-guide/655204/models)

### Quick start

Each example is self-contained. Pick the one you need (`single` or `ha`) and run:

```bash
cd examples/single        # or: cd examples/ha

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set the required values

terraform init
terraform plan
terraform apply
```

Tear everything down with:

```bash
terraform destroy
```

See the example READMEs for the full variable reference, architecture diagrams, outputs, and troubleshooting.

### Licensing

| Type | How to provide the license |
|------|----------------------------|
| **PAYG** | No license input required — set `fmg_license_type = "payg"`. |
| **BYOL (file)** | Set `fmg_license_type = "byol"` and supply the `.lic` file via the relevant `*_byol_license_file` variable. |
| **BYOL (FortiFlex)** | Set `fmg_license_type = "byol"` and supply the token via the relevant `*_byol_fortiflex_license_token` variable. |

### Supported versions

FortiManager 7.0 and above. `fmg_version` accepts:

- Exact version — `"7.6.6"`
- Major.minor — `"7.6"` (latest patch)
- `"latest"` — newest available

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services. For issues, please use the [Issues](https://github.com/40net-cloud/terraform-aws-fortimanager/issues) tab of this project.

## References

- [FortiManager AWS Administration Guide](https://docs.fortinet.com/document/fortimanager-public-cloud/8.0.0/aws-administration-guide/)
- [AWS Marketplace — FortiManager](https://aws.amazon.com/marketplace/pp/prodview-l6rxheua5mbls?sr=0-2&ref_=ucaf&applicationId=AWSMPContessa)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

[License](https://github.com/40net-cloud/terraform-aws-fortimanager/blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
