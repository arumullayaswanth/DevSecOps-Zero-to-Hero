# provider.tf
# AWS provider — credentials come from Vault (dynamic secrets)
# NO access keys here! Vault generates temporary AWS credentials at runtime.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# Vault provider — connects to your Vault server on EC2
# VAULT_ADDR and VAULT_TOKEN are set as environment variables in GitHub Actions
provider "vault" {
  # address and token come from environment variables:
  # VAULT_ADDR  = https://vault.yourdomain.com:8200
  # VAULT_TOKEN = (from GitHub Actions via JWT auth)
}

# Get temporary AWS credentials from Vault's AWS secrets engine
data "vault_aws_access_credentials" "aws_creds" {
  backend = "aws"
  role    = var.vault_aws_role
  type    = "sts" # STS = temporary credentials (expire automatically)
}

# AWS provider uses the temporary credentials from Vault
provider "aws" {
  region     = var.aws_region
  access_key = data.vault_aws_access_credentials.aws_creds.access_key
  secret_key = data.vault_aws_access_credentials.aws_creds.secret_key
  token      = data.vault_aws_access_credentials.aws_creds.security_token

  default_tags {
    tags = {
      Project     = "DevSecOps-Zero-to-Hero"
      Environment = var.environment
      ManagedBy   = "Terraform-Vault"
      Owner       = "yaswanth"
    }
  }
}
