# oidc-role.tf
# This creates the OIDC provider and IAM role that GitHub Actions will assume
# Run this ONCE manually (or via a bootstrap Terraform) to set up trust
#
# After this is created, GitHub Actions can authenticate to AWS WITHOUT access keys

# Step 1: Create OIDC Identity Provider (trusts GitHub)
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "GitHub-Actions-OIDC"
  }
}

# Step 2: IAM Role that GitHub Actions will assume
resource "aws_iam_role" "github_actions" {
  name = "GitHubActions-Terraform-Role"

  # Trust policy — ONLY this specific repo and branch can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # IMPORTANT: Restrict to your specific repo and branch
            # Change this to YOUR GitHub username/repo
            "token.actions.githubusercontent.com:sub" = "repo:arumullayaswanth/DevSecOps-Zero-to-Hero:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name = "GitHub-Actions-Terraform"
  }
}

# Step 3: Attach permissions to the role (what Terraform can create)
resource "aws_iam_role_policy_attachment" "terraform_permissions" {
  role = aws_iam_role.github_actions.name
  # In production, create a CUSTOM policy with only needed permissions
  # Using AdministratorAccess here for demo — DON'T do this in production!
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Output the role ARN (you'll need this in GitHub Actions workflow)
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}
