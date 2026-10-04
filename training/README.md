# Challenge 2 — FortiGate in AWS

## What it deploys

```
Internet ──HTTPS :443 (admin_cidr only)──► Elastic IP
                                               │
VPC 10.0.0.0/16 · IGW · public route table     ▼
 port1 subnet (public)  ── ENI port1 (index 0) ─┐
                                                ├── FortiGate EC2 (c6i.large, PAYG 7.4)
 port2 subnet (private) ── ENI port2 (index 1) ─┘      └─ user_data sets admin password
                     SG fgt-lab on all ENIs · source/dest check off

SSM Parameter Store: /fgt/admins/<name>  (one SecureString per extra admin)
```

```
.
├── main.tf        # provider, AMI lookup, VPC, subnets, IGW, routes, SG, ENIs, EIP, EC2, SSM, outputs
└── variables.tf   # inputs
```

Naming: tags follow `fgt-<interface>` → e.g. `fgt-port1`, `fgt-port2`

## Before you start

```bash
aws configure            # or export AWS_PROFILE=<profile>
aws sts get-caller-identity
```

Subscribe to the **FortiGate PAYG** listing in AWS Marketplace with the same account (once per account). Without it, `apply` fails when launching the instance.

Find your public IP for `admin_cidr`:

```bash
curl -s https://checkip.amazonaws.com
```

`terraform.tfvars` (check `variables.tf` for the full list and defaults):

```hcl
admin_cidr   = "<your-ip>/32"
fgt_password = "ChangeMe-Str0ng!"
fgt_admins = {
  netops   = "Netops-Str0ng-Pass!"
  security = "Security-Str0ng-Pass!"
}
```

## Make it deploy and fix bugs

```bash
terraform init
terraform plan
terraform apply
```

Fix every error. For each bug, write down which command revealed it and why there.

Questions:

1. One `for_each` fails at `plan`. Which values must Terraform know at plan time to build a `for_each`, and why? Which values in this code are only known after `apply`?
2. How do sensitive variables interact with `for_each`? What is the difference between using a sensitive value as a **key** and as a **value**?
3. Why must the `login` output be marked `sensitive`? Run `terraform output login` and `terraform output -raw login` — what is the difference?
4. The admin password is set through `user_data`. Where else can that password be read (hint: EC2 console, `terraform.tfstate`)? How would you avoid that?
5. The AMI comes from a `data` source with `most_recent = true`. What happens to your instance the next time Fortinet publishes a new 7.4 image?

Done when the FortiGate login page opens and the admin password works:

```bash
terraform output -raw gui_url
terraform output -raw login
```

And the extra admins exist in SSM:

```bash
aws ssm get-parameters-by-path --path /fgt/admins --with-decryption \
  --query "Parameters[].Name"
```

## Cleanup

```bash
terraform destroy
```

The instance, EIP and Marketplace PAYG hours cost money — always destroy when finished.
