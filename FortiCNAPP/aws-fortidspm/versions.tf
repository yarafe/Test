terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # module requires >= 6.0 (resource-level `region` argument)
    }
    lacework = {
      source  = "lacework/lacework"
      version = ">= 2.6.0" # lacework_integration_aws_fortidspm first shipped in 2.6.0
    }
  }
}
