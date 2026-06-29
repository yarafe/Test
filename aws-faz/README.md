# FortiAnalyzer Terraform modules for AWS

:wave: - [Introduction](#introduction) - [Architecture & Design](#architecture--design) - [Deployment](#deployment) - [Support](#support) - :wave:

## Introduction

This repository provides Terraform modules for deploying Fortinet FortiAnalyzer on AWS. FortiAnalyzer delivers centralized security logging, analytics, and reporting — collecting and correlating logs from Fortinet devices for visibility, incident analysis, and compliance.

Two deployment patterns are available, each with a reusable module and a ready-to-run example:

- **Single** — one standalone FortiAnalyzer instance.
- **HA** — a clustered deployment supporting active-active (`a-a`) and active-passive (`a-p`) modes.

Both patterns support **BYOL** and **PAYG** licensing, and automatically discover the latest matching Marketplace AMI for the chosen license type and version.

## Architecture & Design

| Pattern | Use when | Failover | Detailed docs |
|---------|----------|----------|---------------|
| **Single** | Labs, PoCs, and non-critical or cost-sensitive deployments | None | [`examples/single/README.md`](examples/single/README.md) |
| **HA** | Production deployments that need resilience or scale-out log ingestion | Active-active or active-passive | [`examples/ha/README.md`](examples/ha/README.md) |

The **single** module provisions one EC2 instance on a management ENI, with an optional Elastic IP and an optional encrypted log volume.

The **HA** module deploys a cluster in one of two modes:

- **Active-passive (`a-p`)** — one active node and a standby, with VRRP-based automatic failover. The floating VIP can be **public** (nodes in separate subnets/AZs, VIP moves to the active node on failover) or **private** — set via `ha_ip = "public" | "private"`.
- **Active-active (`a-a`)** — both nodes process workload concurrently for higher log-ingestion capacity.

The HA README documents each mode, the resulting CLI HA configuration, and failover behavior in detail.

## Repository Structure

```text
terraform-aws-fortianalyzer/
├── modules/
│   ├── single/                  # Single FortiAnalyzer deployment module
│   └── ha/                      # HA deployment module (a-a / a-p)
├── examples/
│   ├── single/                  # Single example (creates VPC + subnet, calls the module)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── ha/                      # HA example
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── list_faz_amis.sh             # Helper: list FortiAnalyzer AMIs by version/region
└── README.md
```

## Deployment

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 and AWS provider >= 5.0
- An existing VPC and subnet(s)
- AWS key pair for SSH access
- For BYOL: a valid FortiAnalyzer license file or FortiFlex token
- [FortiAnalyzer AWS Administration Guide — supported instances and models](https://docs.fortinet.com/document/fortianalyzer-public-cloud/7.6.0/aws-administration-guide/)
- A dedicated, adequately sized log volume — FortiAnalyzer is a logging appliance, so size storage to your retention needs

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
| **PAYG** | No license input required — set `faz_license_type = "payg"`. |
| **BYOL (file)** | Set `faz_license_type = "byol"` and supply the `.lic` file via the relevant `*_byol_license_file` variable. |
| **BYOL (FortiFlex)** | Set `faz_license_type = "byol"` and supply the token via the relevant `*_byol_fortiflex_license_token` variable. |

The modules resolve the AMI automatically from the license type and `faz_version`. To inspect which AMIs are available before deploying:

```bash
./list_faz_amis.sh 7.6            # all regions, version 7.6
./list_faz_amis.sh 7.6 eu-north-1 # specific region
```

### Supported versions

FortiAnalyzer 7.0 and above. `faz_version` accepts:

- Exact version — `"7.6.6"`
- Major.minor — `"7.6"` (latest patch)
- `"latest"` — newest available

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services. For issues, please use the [Issues](https://github.com/40net-cloud/terraform-aws-fortianalyzer/issues) tab of this project.

## References

- [FortiAnalyzer AWS Administration Guide](https://docs.fortinet.com/document/fortianalyzer-public-cloud/7.6.0/aws-administration-guide/)
- [AWS Marketplace — FortiAnalyzer](https://aws.amazon.com/marketplace/seller-profile?id=7de3dd38-52b2-4c1a-9fc1-93e7dfca9d6b)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

[License](https://github.com/40net-cloud/terraform-aws-fortianalyzer/blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
