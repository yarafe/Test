# FortiDSPM scan engine on AWS, single region.
# Module: https://registry.terraform.io/modules/lacework/fortidspm/aws/latest
# Source repo: https://github.com/lacework/terraform-aws-fortidspm

# FortiCNAPP credentials come from the environment:
# LW_ACCOUNT, LW_SUBACCOUNT (org accounts only), LW_API_KEY, LW_API_SECRET.
provider "lacework" {}

# AWS credentials come from the standard AWS credential chain.
provider "aws" {
  region = var.region
}

locals {
  # Every region a scan engine is deployed in. Defaults to the single region.
  regions = length(var.regions) > 0 ? var.regions : [var.region]
}

module "fortidspm" {
  source  = "lacework/fortidspm/aws"
  version = "0.5.0" # latest tag of the module repo; confirm against the registry before apply

  # --- Required -------------------------------------------------------------
  region = var.region # always set it: omitting it deploys into the provider's region
  global = true       # this instance creates the FortiCNAPP DSPM integration; exactly one per deployment
  # global_module_reference is only for non-global instances (additional regions); not used here.

  # --- FortiCNAPP integration ----------------------------------------------
  lacework_integration_name = var.lacework_integration_name
  regions                   = local.regions
  account_id                = var.account_id
  report_deployment_status  = var.report_deployment_status
  enable_cloudtrail         = var.enable_cloudtrail # reserved, currently a no-op in the module

  # --- Networking (isolated VPC built by the module) ------------------------
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  enable_public_ip    = var.enable_public_ip # debugging only
  office_ip           = var.office_ip        # debugging only; needs enable_public_ip = true

  # --- Compute and storage --------------------------------------------------
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type
  log_volume_size  = var.log_volume_size

  # --- Tags -----------------------------------------------------------------
  extra_tags = var.extra_tags
}
