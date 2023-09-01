include "root" {
  path = find_in_parent_folders()
}

# include "region" { path = find_in_parent_folders("region.hcl") }

# locals {
#   account_vars = read_terragrunt_config(find_in_parent_folders())
#   region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
#   service_vars = read_terragrunt_config(find_in_parent_folders("service.hcl"))

#   tags = merge(
#     local.account_vars.locals.tags,
#     local.region_vars.locals.tags,
#     local.service_vars.locals.tags
#   )
# }
# Indicate the input values to use for the variables of the module.
inputs = {
    # profile            = "zultys"                     #zultys
    # availability_zones = ["us-west-2a", "us-west-2b"] #zultys
    # aws_region         = "us-west-2"                  #zultys
    env                = "vv_dev"
}

# remote_state {
#   backend = "s3"
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
#   config = {
#     profile = "zultys"
#     bucket = "vv_my-terraform-state"

#     key = "${path_relative_to_include()}/terraform.tfstate"
#     region         = "us-east-2"
#     encrypt        = true
#     dynamodb_table = "my-lock-table"
#   }
# }


# profile = "zultys"
# region = "us-east-2"
# bucket = "zultys-terraform-state-stage"
# key    = "us-west-2/MX/env/stage/services/mx-ec2.tfstate"
# encrypt = true