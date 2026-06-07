# backend.tf
# Remote state in S3
# 'key' is set here directly (fixed path, won't change)
# Other values passed via -backend-config in GitHub Actions

terraform {
  backend "s3" {
    key = "production/terraform.tfstate"
    # bucket, region, dynamodb_table, encrypt → passed via -backend-config
  }
}
