variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "vault_aws_role" {
  description = "Vault AWS secrets engine role name"
  type        = string
  default     = "terraform-role"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (for practice: open to all)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "replica_region" {
  description = "AWS region for S3 cross-region replication"
  type        = string
  default     = "us-east-1"
}
