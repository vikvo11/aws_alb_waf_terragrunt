resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.bucket_name
  force_destroy = true
  versioning {
    enabled = true
  }
}
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.terraform_up_lock
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
output "BACKEND_REGION" {
  value = var.aws_region
}
output "BACKEND_BUCKET_NAME" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "BACKEND_LOCK_TABLE" {
  value = aws_dynamodb_table.terraform_locks.name
}