###
locals{
    profile             = "${get_env("PROFILE", "default123")}"
    aws_region          = "${get_env("REGION", "")}"
    availability_zones  = "${get_env("AVAILABILITY_ZONES", "" )}"
    backend_region      = "${get_env("BACKEND_REGION", "${local.aws_region}" )}"
    backend_bucket_name = "${get_env("BACKEND_BUCKET_NAME", "" )}"
    backend_lock_table  = "${get_env("BACKEND_LOCK_TABLE", "" )}"
    module_version      = "${get_env("MODULE_VERSION", "latest")}"
    name                = "${get_env("NAME", "default_name")}"
    type                = "${get_env("ENVIRONMENT", "nonprod")}"
}
terraform {
before_hook "confirmation_hook" {
  commands     = ["apply"]
  execute      = ["sh", "-c", "if [ \"${local.type}\" = \"prod\" ]; then read -p 'Are you sure you want to apply in production? (y/N): ' yn; case $yn in [Yy]* ) ;; * ) echo 'Aborted. No changes were made.' ; exit 1;; esac; fi"]
}
source = "modules/ALB_WAF/${local.module_version}"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {
    profile =  "${local.profile}"
    #bucket = "${local.type}-terraform-state"
    bucket = "${local.backend_bucket_name}"

    key = "${path_relative_to_include()}/${local.name}.tfstate"
    region         = "${local.backend_region}"#"${local.aws_region}"#"us-east-2"
    encrypt        = true
    #dynamodb_table = "my-lock-table"
    dynamodb_table = "${local.backend_lock_table}"#"my-lock-table"
  }
}
EOF
}
####

# Indicate what region to deploy the resources into
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  profile = "${local.profile}"#var.profile
  region  = "${local.aws_region}"#var.aws_region
}
EOF
}

# Indicate the input values to use for the variables of the module.
inputs = {
    profile            = local.profile               
    availability_zones = local.availability_zones #["us-west-2a", "us-west-2b"] 
    aws_region         = local.aws_region #"us-west-2"                  
    env                = "vv__${local.name}"
    module_version     = local.module_version
}