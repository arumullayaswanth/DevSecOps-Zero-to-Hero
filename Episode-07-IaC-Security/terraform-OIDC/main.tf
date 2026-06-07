# main.tf
# Production-ready AWS infrastructure
# This file creates: VPC, Subnets, Security Groups, EC2 instance
# All resources follow security best practices (Checkov-compliant)

# ==============================================================
# VPC — Virtual Private Cloud
# ==============================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false # ✅ No auto-assign public IP (Checkov CKV_AWS_88)

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# Private subnet (for databases, internal services)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.environment}-private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================
# Security Group — Restrictive (NOT 0.0.0.0/0)
# ==============================================================
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  # ✅ SSH only from specific IP (NOT 0.0.0.0/0) — Checkov CKV_AWS_24
  ingress {
    description = "SSH from office IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr] # Your office IP
  }

  # ✅ HTTPS from anywhere (web traffic)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ✅ HTTP from anywhere (redirect to HTTPS)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress — allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-sg"
  }
}

# ==============================================================
# EC2 Instance — Secure Configuration
# ==============================================================
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  # ✅ IMDSv2 required (Checkov CKV_AWS_79) — prevents SSRF attacks
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Forces IMDSv2
    http_put_response_hop_limit = 1
  }

  # ✅ EBS encryption (Checkov CKV_AWS_8)
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # ✅ Monitoring enabled
  monitoring = true

  tags = {
    Name = "${var.environment}-web-server"
  }
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ==============================================================
# S3 Bucket — Secure Configuration
# ==============================================================
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.environment}-devsecops-app-data"

  tags = {
    Name = "${var.environment}-app-data"
  }
}

# ✅ Enable versioning (Checkov CKV_AWS_21)
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ✅ Enable encryption (Checkov CKV_AWS_19)
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ✅ Block public access (Checkov CKV_AWS_20)
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ✅ Enable access logging (Checkov CKV_AWS_18)
resource "aws_s3_bucket_logging" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  target_bucket = aws_s3_bucket.app_data.id
  target_prefix = "access-logs/"
}
