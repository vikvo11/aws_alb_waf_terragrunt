locals{
    profile             = "${get_env("PROFILE", "default123")}"
    aws_region          = "${get_env("REGION", "")}"
    bucket_name         = "${get_env("BACKEND_BUCKET_NAME", "")}"
    terraform_up_lock   = "${get_env("BACKEND_LOCK_TABLE", "")}"
}
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

inputs = {
        profile            = local.profile               
        aws_region         = local.aws_region
        bucket_name        = local.bucket_name
        terraform_up_lock  = local.terraform_up_lock
}