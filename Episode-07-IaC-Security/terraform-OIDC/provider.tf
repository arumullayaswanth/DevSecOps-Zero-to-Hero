# provider.tf
# AWS provider configuration
# NOTE: No access keys here! Authentication happens via OIDC in GitHub Actions
# or via AWS CLI profile when running locally

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Pin to major version 5.x
    }
  }
}

provider "aws" {
  region = var.aws_region

  # No access_key or secret_key here!
  # In GitHub Actions: OIDC provides temporary credentials
  # Locally: Uses AWS CLI profile or environment variables

  default_tags {
    tags = {
      Project     = "DevSecOps-Zero-to-Hero"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "yaswanth"
    }
  }
}
