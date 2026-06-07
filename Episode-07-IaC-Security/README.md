# Episode 07 - Infrastructure as Code (IaC) Security

## 🎯 Episode Structure (1 Hour)

| # | Topic | Duration | Focus |
|---|-------|----------|-------|
| 1 | How Companies Create Infrastructure | 15 min | The production workflow |
| 2 | Terraform + GitHub Actions + OIDC (No Access Keys) | 25 min | Secure automation |
| 3 | Checkov — IaC Security Scanning | 20 min | Catch misconfigurations before deploy |

---

## 📁 Files in This Folder

### Method 1: OIDC 

| File/Folder | Purpose |
|-------------|---------|
| `terraform-OIDC/provider.tf` | AWS provider (uses OIDC) |
| `terraform-OIDC/backend.tf` | S3 remote state (key hardcoded) |
| `terraform-OIDC/variables.tf` | Configurable values with defaults |
| `terraform-OIDC/main.tf` | VPC, EC2, S3 — all Checkov-compliant |
| `terraform-OIDC/oidc-role.tf` | GitHub OIDC trust role |
| `terraform-OIDC/outputs.tf` | Display values after apply |
| `.github/workflows/terraform-oidc.yml` | GitHub Actions workflow |
| `process-oidc.md` | Step-by-step OIDC setup guide |

### Method 2: Vault (Advanced — Vault on EC2)

| File/Folder | Purpose |
|-------------|---------|
| `terraform-vault/provider.tf` | AWS provider (credentials from Vault) |
| `terraform-vault/backend.tf` | S3 remote state (key hardcoded) |
| `terraform-vault/variables.tf` | Configurable values with defaults |
| `terraform-vault/main.tf` | VPC, EC2, S3 — all Checkov-compliant |
| `terraform-vault/outputs.tf` | Display values after apply |
| `.github/workflows/terraform-vault.yml` | GitHub Actions workflow |
| `process-vault.md` | Step-by-step Vault setup guide |

### Shared

| File | Purpose |
|------|---------|
| `Checkov.md` | Checkov scanning documentation |

---

### GitHub Variables — OIDC Method (4 variables only)

| Variable | Example |
|----------|---------|
| `AWS_REGION` | `ap-south-1` |
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActions-Terraform-Role` |
| `TF_STATE_BUCKET` | `devsecops-terraform-state-2025` |
| `TF_LOCK_TABLE` | `terraform-state-lock` |

### GitHub Variables — Vault Method (5 variables only)

| Variable | Example |
|----------|---------|
| `VAULT_ADDR` | `http://YOUR_EC2_IP:8200` |
| `VAULT_ROLE` | `github-actions-role` |
| `AWS_REGION` | `ap-south-1` |
| `TF_STATE_BUCKET` | `devsecops-terraform-state-2025` |
| `TF_LOCK_TABLE` | `terraform-state-lock` |

> Everything else (working directory, state key, VPC CIDR, instance type, SSH CIDR) is set directly in the code with defaults.

---

## 1️⃣ How  Companies Create Infrastructure (15 min)

### ❌ Wrong Way (What Most Beginners Do)

```
Developer → Create AWS Access Key → Put in GitHub Secrets → terraform apply in GitHub Actions
```

**Problems:**
- Long-lived AWS access keys (if leaked, attacker has full access)
- Keys stored in GitHub Secrets (anyone with repo access can use them)
- Manual key rotation (teams forget to rotate)
- No audit trail of who applied what
- Single set of credentials for all environments

### ✅ Right Way (How Production Companies Do It)

```
Developer → Create PR → GitHub Actions runs terraform plan → Reviewer approves PR
→ PR merged to main → GitHub Actions assumes AWS Role via OIDC (no keys!)
→ terraform apply runs → Infrastructure created
```

### The Production Workflow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   Company IaC Workflow                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Developer creates branch and writes Terraform code                  │
│  2. Developer pushes code and creates Pull Request                      │
│  3. GitHub Actions triggers automatically:                              │
│     → terraform fmt (format check)                                      │
│     → terraform validate (syntax check)                                 │
│     → checkov scan (security scan)                                      │
│     → terraform plan (show what will change)                            │
│     → Plan output posted as PR comment                                  │
│  4. Team lead / reviewer reviews the plan                               │
│  5. PR is approved and merged to main                                   │
│  6. GitHub Actions on main branch:                                      │
│     → Authenticates to AWS using OIDC (no access keys!)                 │
│     → terraform apply (creates/updates infrastructure)                  │
│  7. State stored in S3 bucket (encrypted, versioned, locked)            │
│                                                                         │
│  To destroy: Developer creates PR with destroy flag or removes code     │
│  Same approval process → merge → terraform destroy                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key Differences from Beginner Approach

| Aspect | ❌ Wrong (Beginner) | ✅ Right (Production) |
|--------|---------------------|----------------------|
| Authentication | AWS Access Keys in GitHub Secrets | OIDC — temporary tokens, no keys stored |
| State file | Local or unprotected S3 | Encrypted S3 + state locking |
| Apply | Anyone can run `terraform apply` | Only runs after PR merge + approval |
| Review | No review before changes | Plan posted on PR, team reviews |
| Destroy | Manual `terraform destroy` | PR-based or workflow dispatch (controlled) |
| Secrets | Hardcoded in `.tf` files or env vars | AWS Secrets Manager (never hardcoded) |
| Scanning | No scanning | Checkov scans every PR |

---

## 2️⃣ Terraform + GitHub Actions + OIDC (25 min)

### What is OIDC?

**OIDC (OpenID Connect)** lets GitHub Actions assume an AWS IAM role WITHOUT storing any AWS access keys. GitHub proves its identity to AWS using a signed JWT token.

```
GitHub Actions                         AWS
─────────────                         ───
"I am repo arumullayaswanth/         "I trust GitHub.
 DevSecOps-Zero-to-Hero,              If the repo and branch match,
 running on branch main"    ───────►   here are temporary credentials
                                       (valid for 1 hour only)"
```

### Step 1: Create OIDC Provider in AWS

```bash
# This tells AWS to trust GitHub as an identity provider
# Run this ONCE in your AWS account (via console or Terraform)

aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 2: Create IAM Role for GitHub Actions

This role has the permissions your Terraform needs (EC2, VPC, S3, etc.)
and trusts ONLY your specific repository and branch.

See: `terraform-OIDC/oidc-role.tf`

### Step 3: Configure Terraform Backend (S3 + Locking)

State file is stored in S3 with:
- Encryption at rest (AES-256)
- Versioning (rollback if state corrupted)
- State locking (prevents two people applying at same time)

See: `terraform-OIDC/backend.tf`

### Step 4: GitHub Actions Workflow

- On PR: `terraform plan` + Checkov scan + post plan as comment
- On merge to main: `terraform apply`
- Manual trigger: `terraform destroy` (with approval)
- All config stored in GitHub Variables (no hardcoding in workflow file)

See: `.github/workflows/terraform-oidc.yml`

For the complete step-by-step setup guide, see: **[process-oidc.md](./process-oidc.md)**

---

## 3️⃣ Checkov — IaC Security Scanning (20 min)

### What is Checkov?

Checkov scans your Terraform, Kubernetes, Dockerfile, and CloudFormation files for security misconfigurations BEFORE you deploy.

### Installation

```bash
# Install Checkov
pip install checkov

# Verify
checkov --version
```

### Basic Usage

```bash
# Scan all Terraform files in current directory
checkov -d .

# Scan a specific file
checkov -f main.tf

# Scan and output as JSON
checkov -d . -o json

# Scan only for HIGH and CRITICAL severity
checkov -d . --check-severity HIGH,CRITICAL

# Skip specific checks (if you have a valid reason)
checkov -d . --skip-check CKV_AWS_79,CKV_AWS_18
```

### Common Checkov Findings for AWS

| Check ID | What It Catches |
|----------|----------------|
| CKV_AWS_79 | EC2 instance metadata not secured (IMDSv2) |
| CKV_AWS_18 | S3 bucket without access logging |
| CKV_AWS_19 | S3 bucket without encryption |
| CKV_AWS_20 | S3 bucket is publicly accessible |
| CKV_AWS_23 | Security group allows 0.0.0.0/0 ingress |
| CKV_AWS_24 | Security group allows SSH from 0.0.0.0/0 |
| CKV_AWS_88 | EC2 instance has public IP |
| CKV_AWS_126 | RDS instance is publicly accessible |
| CKV_AWS_145 | RDS storage not encrypted |

### Checkov in GitHub Actions

Checkov runs automatically on every PR — if security issues are found, the PR is blocked.

```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    directory: terraform-OIDC/
    framework: terraform
    output_format: sarif
    soft_fail: false  # false = block PR if issues found
```

---

## 📋 IaC Security Checklist

- [ ] Use OIDC for authentication (no long-lived access keys)
- [ ] Store state in encrypted S3 with versioning and locking
- [ ] Run `terraform plan` on PR, `terraform apply` only after merge
- [ ] Scan with Checkov on every PR (block if issues found)
- [ ] Never hardcode secrets in Terraform files
- [ ] Use AWS Secrets Manager for sensitive values (DB passwords, API keys)
- [ ] Pin provider and module versions
- [ ] Enable IMDSv2 on all EC2 instances
- [ ] No security groups allowing 0.0.0.0/0
- [ ] Encrypt all storage (S3, EBS, RDS)
- [ ] Use separate AWS accounts for dev/staging/production
- [ ] Enable CloudTrail for audit logging

---

## 📚 Resources

- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
- [AWS IAM OIDC Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)

## 🎓 Free Course

- [Developing Secure Software (LFD121)](https://openssf.org/training/courses/) — Free course by OpenSSF
