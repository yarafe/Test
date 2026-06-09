# Basic configuration
prefix     = "fmgtest"
region     = "us-west-2"
username   = "admin"
password   = "Change.Me.123"

# Network configuration
vpc_cidr   = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"
availability_zone = "us-west-2a"

# FortiManager configuration
fmg_vmsize = "m5.2xlarge"
fmg_license_type = "payg"  # or "byol"
fmg_version = "7.6.6"
key_name    = "your-key-pair-name"
admin_cidr  = ["0.0.0.0/0"]  # Restrict this in production
# fmg_byol_license_file = "path/to/license.lic"  # Only needed for BYOL
