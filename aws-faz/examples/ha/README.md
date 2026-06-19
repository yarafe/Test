# AWS FortiAnalyzer HA Terraform Module

:wave: - [Introduction](#introduction) - [Architecture & Design](#architecture--design) - [HA Modes Configurations](#ha-modes-configurations) - [Terraform Deployment](#terraform-deployment) - [Troubleshooting](#troubleshooting) - :wave:

## Introduction

This repository contains Terraform modules for deploying Fortinet FortiAnalyzer on AWS in a High Availability (HA) cluster. FortiAnalyzer provides centralized log collection, analytics, reporting, and incident management for Fortinet devices. The module automates the compute, networking, IAM, and security-group resources required for a two-node FortiAnalyzer cluster, supporting both active-passive and active-active operation.

## Architecture & Design

The module deploys two FortiAnalyzer EC2 instances (`faz1`/`faz2`) and wires them into an HA cluster. Cluster role, virtual IP behavior, and subnet placement all depend on the chosen HA mode.

The module supports three topologies, selected by `ha_mode` (`a-p` or `a-a`) and, for active-passive, `ha_ip` (`public` or `private`):

1. **Active-Passive with Public VIP** 

FortiAnalyzer A and FortiAnalyzer B land in different subnets / AZs — cross-AZ resilience. Each node gets its own management EIP, plus a public VIP that fronts the cluster.
On failover, FortiAnalyzer uses its instance IAM role to reassociate the public VIP to the new primary node.
Only the HA primary can receive logs and archive files from its directly connected device and forward them to HA secondary.

![FortiAnalyzer Active-Passive Public VIP design](images/faz-a-p-public-vip.png)

2. **Active-Passive with Private VIP** 

Both nodes sit in the same subnet / AZ. By default, no public IP addresses are assigned to the FortiAnalyzer instances. If direct management access from the internet is required, you can optionally assign public IP addresses to the management interfaces of the FortiAnalyzer nodes. FortiAnalyzer A's ENI carries two private IPs: a primary address and the secondary private VIP HA address. Failover moves this secondary private IP between nodes.

![FortiAnalyzer Active-Passive Private VIP design](images/faz-a-p-private-vip.png)

3. **Geo-Redundant Active-Active**

FortiAnalyzer A and FortiAnalyzer B land in different subnets / AZs. Each node gets its own EIP; there is no VIP. Both nodes are active and can receive logs and archive files from its directly connected device and forward logs and archive files to its HA peer.

![FortiAnalyzer Active-Active design](images/faz-a-a.png)

**Deployed Components**

| Component | Resource | Notes |
|-----------|----------|-------|
| Compute | `aws_instance.faz1`, `aws_instance.faz2` | `m5.xlarge` by default; encrypted gp2 100 GB root volume each |
| Log storage | `aws_ebs_volume.faz{1,2}_logs` | Optional, encrypted gp3 500 GB volume per node, mounted as `/dev/sdf` |
| Networking | `aws_network_interface.faz{1,2}` | One ENI per node; `faz1` ENI holds the floating private VIP in active-passive private mode |
| Public addressing | `aws_eip.faz1`, `aws_eip.faz2`, `aws_eip.vip` | `faz1`/`faz2` EIPs in a-a and a-p public; `vip` EIP only in a-p public |
| Access control | `aws_security_group.fortianalyzer` | Ingress for management, logging, and HA (see below) |
| Permissions | `aws_iam_role` / `aws_iam_instance_profile` | Optional (off by default); grants IP/EIP-move permissions for failover |
| AMI | `data.aws_ami.fortianalyzer_{byol,payg}` | Latest Marketplace AMI for the chosen license type/version |

**Security group ingress**

The cluster heartbeat/election runs over VRRP (IP protocol 112) and data sync over TCP 5199 between the two nodes. The module includes a broad "all traffic from the VPC CIDR" rule, which is what currently permits VRRP and 5199 between peers — see [Limitations](#limitations) for tightening this.

| Port / Protocol | Source | Purpose |
|-----------------|--------|---------|
| TCP 22 | `admin_cidr` | SSH access |
| TCP 443 | `admin_cidr` | HTTPS management UI |
| TCP 541 | `fortigate_cidr` | FGFM — secure device/log transmission |
| UDP 514 | `fortigate_cidr` | Syslog reception |
| TCP 5199 | `0.0.0.0/0` | FortiAnalyzer HA synchronization |
| All (protocol -1) | VPC CIDR | Intra-VPC traffic — covers VRRP (112) heartbeat and 5199 sync between peers |

**IAM Permissions**

Set `create_iam_role = true` so FortiAnalyzer can move the VIP/secondary IP during failover.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AssignPrivateIpAddresses",
        "ec2:DescribeSubnets",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeAddresses",
        "ec2:AssociateAddress",
        "ec2:CreateTags",
        "s3:GetObject"
      ],
      "Resource": "*"
    }
  ]
}
```

## HA Modes Configurations

1. **VRRP Automatic Failover with Public VIP**

**FortiAnalyzer A**
<pre><code>
config system ha
    set mode a-p
    set group-id 1
    set group-name FAZHA
    set hb-interface port1
    <b>set initial-sync enable</b>
    set hb-interval 5
    set hb-lost-threshold 10
    set password <b>ha_password</b>
    set priority 100
    set preferred-role primary
    config peer
        edit 1
            set addr <b>FortiAnalyzer B Private IP address</b>
            set serial-number <b>FortiAnalyzer B serial number</b>
        next
    end
    config vip
        edit 1
            set vip <b>FortiAnalyzer HA Public IP address</b>
            set vip-interface port1
        next
    end
end
</code></pre>

**FortiAnalyzer B**

<pre><code>
config system ha
    set mode a-p
    set group-id 1
    set group-name FAZHA
    set hb-interface port1
    set hb-interval 5
    set hb-lost-threshold 10
    set password <b>ha_password</b>
    set priority 1
    set preferred-role secondary
    config peer
        edit 1
            set addr <b>FortiAnalyzer A Private IP address</b>
            set serial-number <b>FortiAnalyzer A serial number</b>
        next
    end
    config vip
        edit 1
            set vip <b>FortiAnalyzer HA Public IP address</b>
            set vip-interface port1
        next
    end
end
</code></pre>


2. **Active-Passive with Private VIP** 

**FortiAnalyzer A**

<pre><code>
config system ha
    set mode a-p
    set group-id 1
    set group-name FAZHA
    set hb-interface port1
    <b>set initial-sync enable</b>
    set hb-interval 5
    set hb-lost-threshold 10
    set password <b>ha_password</b>
    set priority 100
    set preferred-role primary
    config peer
        edit 1
            set addr <b>FortiAnalyzer B Private IP address</b>
            set serial-number <b>FortiAnalyzer B serial number</b>
        next
    end
    config vip
        edit 1
            set vip <b>FortiAnalyzer HA Private IP address</b>
            set vip-interface port1
        next
    end
end
</code></pre>
**FortiAnalyzer B**

<pre><code>
config system ha
    set mode a-p
    set group-id 1
    set group-name FAZHA
    set hb-interface port1
    set hb-interval 5
    set hb-lost-threshold 10
    set password <b>ha_password</b>
    set priority 1
    set preferred-role secondary
    config peer
        edit 1
            set addr <b>FortiAnalyzer A Private IP address</b>
            set serial-number <b>FortiAnalyzer A serial number</b>
        next
    end
    config vip
        edit 1
            set vip <b>FortiAnalyzer HA Private IP address</b>
            set vip-interface port1
        next
    end
end
</code></pre>

3. **Geo-Redundant Active-Active**

**FortiAnalyzer A**
<pre><code>
config system ha
    set mode a-a
    set group-id 1
    set group-name FAZHA
    set hb-interface port1
    <b>set initial-sync enable</b>
    set hb-interval 5
    set hb-lost-threshold 10
    set password <b>ha_password</b>
    set priority 100
    set preferred-role primary
    config peer
        edit 1
            set addr <b>FortiAnalyzer B Private IP address</b>
            set serial-number <b>FortiAnalyzer B serial number</b>
        next
    end
end
</code></pre>

**FortiAnalyzer B**

<pre><code>
config system ha
    set mode a-a
    set group-id 1
    set group-name FAZHA
    set hb-interface port1
    set hb-interval 5
    set hb-lost-threshold 10
    set password <b>ha_password</b>
    set priority 1
    set preferred-role secondary
    config peer
        edit 1
            set addr <b>FortiAnalyzer A Private IP address</b>
            set serial-number <b>FortiAnalyzer A serial number</b>
        next
    end
end
</code></pre>

## Terraform Deployment

### Prerequisites and Requirements

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 and AWS provider >= 5.0
- An existing VPC and the required subnets/AZs (see `subnet_ids` rules)
- AWS key pair for SSH access (optional)
- For BYOL: valid FortiAnalyzer license files or FortiFlex tokens, plus the appliance serial numbers
- [FortiAnalyzer supported instances](https://docs.fortinet.com/document/fortianalyzer-public-cloud/8.0.0/aws-administration-guide/369910/instance-type-support)
- [FortiAnalyzer requires a minimum disk size of 500 GB](https://docs.fortinet.com/document/fortianalyzer-public-cloud/8.0.0/aws-administration-guide/571011/deploying-fortianalyzer-vm-using-manual-launch )
- During deployment the aws certificate (Amazon-RSA-2048-M01) added for both FortiAnalyzers. This certificate can also be downloaded from this [link](https://www.amazontrust.com/repository/)

### Features

- **Three HA topologies**: active-passive with a public VIP, active-passive with a private VIP, or active-active — selected with `ha_mode` and `ha_ip`
- **Automated AMI Discovery**: Automatically finds the latest FortiAnalyzer AMI based on license type (BYOL/PAYG) and version
- **Flexible Licensing**: Support for both BYOL (Bring Your Own License) and PAYG (Pay As You Go) deployments
- **Security**: Pre-configured security group with rules for management, log collection, and HA sync
- **Storage**: Configurable, encrypted root and log volumes per node
- **IAM Integration**: Optional IAM role granting the IP/EIP-move permissions needed for failover

### Module Structure

```
terraform-aws-fortianalyzer/
├── modules/
│   ├── ha/                       # HA FortiAnalyzer deployment module
├── examples/
│   ├── ha/                       # HA example deployment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars.example
│   │   ├── outputs.tf
└── README.md
```
### Recommendations

1. **Restrict Management Access**: Set `admin_cidr` to specific ranges and narrow the SSH rule from `0.0.0.0/0`.
2. **Enable the IAM Role**: Use `create_iam_role = true` for active-passive failover.
3. **Use Private Subnets**: Deploy in private subnets with a VPC endpoint for the EC2 API where possible.
4. **Enable Encryption**: Root and log volumes are encrypted by default — keep it that way.
5. **Regular Updates**: Keep the FortiAnalyzer version updated

### Instructions

- Copy all Terraform configuration files into your working directory. Then, rename the file terraform.tfvars.example to terraform.tfvars. 
The terraform.tfvars file contains all configurable input variables for the deployment. 

- Set the variables from terraform.tfvars file

- Run the following commands:

```bash
terraform init
terraform plan
terraform apply
```
- You can delete the integration and remove all created resources using the following command:

```bash
terraform destroy
```
## Outputs

The module provides comprehensive outputs including:
- Instance information (ID, IPs, state)
- Network details (security groups, interfaces)
- Management URLs and SSH connection strings
- Storage and IAM resource information



### Limitations

- **Subnet count is mode-dependent.** Active-passive with a private VIP requires exactly 1 subnet and 1 AZ; all other modes require exactly 2 (enforced by variable validation).
- **`create_iam_role` defaults to `false`.** Active-passive failover relies on the appliance moving the VIP/secondary IP via the AWS API, which needs this role. Set `create_iam_role = true` for a-p deployments.
- **AWS API reachability is required for failover.** The VIP/secondary IP only moves when FortiAnalyzer can reach the AWS EC2 API. For air-gapped / no-internet deployments, create an interface VPC endpoint for `com.amazonaws.<region>.ec2`.
- **Permissive security group.** The module includes a broad "all traffic from the VPC CIDR" ingress rule and opens SSH (TCP 22) to `0.0.0.0/0`. Tighten both before production. There is also a malformed `protocol = "22"` rule that can be removed.
- **IMDSv2 not enforced.** The instances allow `http_tokens = "optional"` (IMDSv1). Set to `"required"` unless a dependency prevents it.


## Troubleshooting

Run the following commands in the FortiAnalyzer CLI:

- `get system ha-status`
- `diagnose system ha status`

Enable HA debug output (run on both nodes before/while forming the cluster to surface errors):

```
diagnose debug application ha 255
```

Force a configuration re-sync if logs synced but configuration did not:

```
diagnose ha force-cfg-resync
```

Common issues:
- **Cluster never forms** — do not enable initial sync on both nodes at once. Enable `initial-sync` on the primary only; stop sync on the secondary (or reboot it), then sync from the primary.
- **VIP does not move on failover** — confirm `create_iam_role = true` and that the instances can reach the AWS EC2 API (internet or a VPC endpoint).
- **Peers cannot reach each other** — verify VRRP (IP protocol 112) and TCP 5199 are allowed between the nodes (covered by the VPC-CIDR rule, but confirm if you tighten the security group).
- **Preemption (v7.4.7 / v7.6.2 and later)** — preemption is enabled by default when a node's preferred role is primary; disable it if you do not want automatic failback.
- **After deployment , it could require to retype ha password**

You can find additional HA commands in the [FortiAnalyzer CLI reference](https://docs.fortinet.com/document/fortianalyzer/8.0.0/cli-reference).

## Support

For issues and questions:
1. Check the [examples](../../examples/) for common use cases
2. Review Fortinet documentation for FortiAnalyzer
3. Open an issue in this repository

## References

- [FortiAnalyzer AWS Administration Guide](https://docs.fortinet.com/document/fortianalyzer-public-cloud/8.0.0/aws-administration-guide/)
- [Setting up a FortiAnalyzer HA cluster](https://docs.fortinet.com/document/fortianalyzer/7.4.0/examples/201115/setting-up-a-fortianalyzer-ha-cluster)
- [FortiAnalyzer HA Configuration and Troubleshooting (Fortinet Community)](https://community.fortinet.com/t5/FortiAnalyzer/Technical-Tip-FortiAnalyzer-HA-Configuration-and-Troubleshooting/ta-p/219808)
- [AWS Marketplace - FortiAnalyzer](https://aws.amazon.com/marketplace/seller-profile?id=7de3dd38-52b2-4c1a-9fc1-93e7dfca9d6b)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
