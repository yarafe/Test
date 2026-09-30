# Challenge 3: App Deployment in AWS


## What it deploys

```
Internet ──HTTP :80──► ALB (dev-app-alb-xxxxxx) ──HTTP :80──► EC2 nginx (dev-app-ec2)
                        │                                         │
                        └─ access logs ► S3 bucket                └─ IAM role ► reads DB password from SSM
VPC 10.20.0.0/16 · 2 public subnets · IGW · route table
```

```
.
├── main.tf / variables.tf / outputs.tf        # root: network + module call
└── modules/web_service/
    └── main.tf / variables.tf / outputs.tf    # ALB, TG, EC2, SGs, IAM, S3, SSM
```

Naming convention: `<env>-<service>-<resource>[-<suffix>]` → e.g. `dev-app-alb-k3x9p2`

## Rules

- Do **not** delete or loosen any `validation` block.
- AWS limits: ALB / target group name ≤ 32 chars (letters, digits, hyphens); S3 bucket name 3–63 chars, `a-z 0-9 - .` only.
- Region `eu-west-1`. Cost ≈ ALB + t3.micro, a few cents per hour. **Destroy at the end of the day.**
- Terraform ≥ 1.5.

---

## Part 1 — Make it deploy (2 bugs)

```bash
terraform init
terraform plan
terraform apply
```

Fix every error. For each bug, write down **which command** revealed it and **why there**.

Questions:
1. Why does one bug appear only at `apply`, even though `plan` was clean?
2. After the failed `apply`, run `terraform state list`. What already exists in AWS? Will the next `apply` recreate it?

Done when `app_url` (http://…) opens a page in your browser. From the terminal: `curl $(terraform output -raw app_url)`.

---

## Part 2 — State challenge: lost and found

run
```bash
terraform state rm module.app.aws_s3_bucket_policy.alb_logs
```

Tasks:
1. Prove the bucket policy still exists in AWS.
2. Run `terraform plan`. What does Terraform want to do, and what would happen in AWS if you applied it?
3. Bring the policy back under Terraform management using an **`import` block** (no `terraform import` CLI).

## Cleanup

```bash
terraform destroy
```
