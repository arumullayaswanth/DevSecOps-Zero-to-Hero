# provider.tf
# AWS provider — credentials come from environment variables
# GitHub Actions vault-action sets AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# Terraform automatically picks them up — no config needed here

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # No access_key or secret_key here!
  # Terraform automatically uses AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
  # from environment variables (set by vault-action in GitHub Actions)

  default_tags {
    tags = {
      Project     = "DevSecOps-Zero-to-Hero"
      Environment = var.environment
      ManagedBy   = "Terraform-Vault"
      Owner       = "yaswanth"
    }
  }
}
