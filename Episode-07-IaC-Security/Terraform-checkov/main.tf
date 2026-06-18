

resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-public-demo-bucket"
}

resource "aws_s3_bucket_acl" "public_acl" {
  bucket = aws_s3_bucket.public_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.public_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}




# resource "aws_s3_bucket" "secure_bucket" {
#   bucket = "my-secure-demo-bucket"
# }

# resource "aws_s3_bucket_versioning" "secure_bucket" {
#   bucket = aws_s3_bucket.secure_bucket.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
#   bucket = aws_s3_bucket.secure_bucket.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "aws:kms"
#     }
#     bucket_key_enabled = true
#   }
# }

# resource "aws_s3_bucket_public_access_block" "secure_access" {
#   bucket                  = aws_s3_bucket.secure_bucket.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_logging" "secure_bucket" {
#   bucket        = aws_s3_bucket.secure_bucket.id
#   target_bucket = aws_s3_bucket.secure_bucket.id
#   target_prefix = "logs/"
# }

# resource "aws_s3_bucket_lifecycle_configuration" "secure_bucket" {
#   bucket = aws_s3_bucket.secure_bucket.id

#   rule {
#     id     = "cleanup"
#     status = "Enabled"

#     noncurrent_version_expiration {
#       noncurrent_days = 90
#     }

#     abort_incomplete_multipart_upload {
#       days_after_initiation = 7
#     }
#   }
# }

# resource "aws_s3_bucket_notification" "secure_bucket" {
#   bucket      = aws_s3_bucket.secure_bucket.id
#   eventbridge = true
# }
