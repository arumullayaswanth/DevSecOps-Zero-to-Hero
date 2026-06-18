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

provider "vault" {}

data "vault_aws_access_credentials" "aws_creds" {
  backend = "aws"
  role    = var.vault_aws_role
  type    = "sts"
}

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

provider "aws" {
  alias      = "replica"
  region     = var.replica_region
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
