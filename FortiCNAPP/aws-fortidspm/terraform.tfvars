# --- Required ---------------------------------------------------------------
region = "<change-me>" # for example "eu-west-1"

# --- FortiCNAPP integration (defaults shown) --------------------------------
# regions                   = []              # empty = [region]
# lacework_integration_name = "aws-fortidspm"
# account_id                = ""              # empty = caller identity's account
# report_deployment_status  = true
# enable_cloudtrail         = false           # reserved, no-op

# --- Networking (defaults shown) --------------------------------------------
# vpc_cidr            = "10.0.0.0/16"
# public_subnet_cidr  = "10.0.0.0/24"
# private_subnet_cidr = "10.0.1.0/24"
# enable_public_ip    = false                 # debugging only
# office_ip           = ""                    # debugging only, e.g. "203.0.113.4/32"

# --- Compute and storage (defaults shown) -----------------------------------
# instance_type    = ""                       # empty = first of m5/m6i/m7i.2xlarge offered in the region
# root_volume_size = 8                        # must be < 10
# root_volume_type = "gp3"
# log_volume_size  = 512

# --- Tags -------------------------------------------------------------------
# extra_tags = {}
