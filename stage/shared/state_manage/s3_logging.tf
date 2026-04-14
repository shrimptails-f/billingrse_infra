resource "aws_s3_bucket" "tfstate_logs" {
  bucket = "${local.state_bucket_name}-logs"

  tags = {
    Stage = module.env.stage
  }
}

resource "aws_s3_bucket_logging" "tfstate" {
  bucket        = aws_s3_bucket.tfstate.id
  target_bucket = aws_s3_bucket.tfstate_logs.id
  target_prefix = "access-logs/"

  depends_on = [aws_s3_bucket_acl.tfstate_logs]
}

# アクセスログは溜まりやすいので30日で自動削除
resource "aws_s3_bucket_lifecycle_configuration" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  rule {
    id     = "expire-logs-30days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
