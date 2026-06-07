# Step-by-Step Process: Vault on EC2 + GitHub Actions + Terraform

This document explains how to deploy HashiCorp Vault on an EC2 instance and configure it to provide temporary AWS credentials to GitHub Actions for Terraform.

---

## Architecture

```
GitHub Actions → (JWT Token) → Vault (EC2) → (STS) → AWS (temporary credentials)
     │                              │                        │
     │  1. Send JWT token           │  2. Validate JWT       │
     │                              │  3. Generate AWS creds │
     │                              │                        │
     └──── 4. Use temp creds ───────┴────────────────────────┘
                to run Terraform
```

---

## Why Vault Instead of Direct OIDC?

| Feature | Direct OIDC | Vault |
|---------|------------|-------|
| Setup complexity | Simple | More complex |
| Secret rotation | N/A | Automatic |
| Credential scope | IAM Role level | Fine-grained per-path |
| Audit logging | CloudTrail only | Vault audit + CloudTrail |
| Multi-cloud | One provider at a time | AWS + GCP + Azure from one Vault |
| Database secrets | Not possible | Dynamic DB credentials |
| Best for | Simple setups | Enterprise, multi-team, multi-cloud |

---

## Prerequisites

- [ ] AWS Account
- [ ] GitHub Repository
- [ ] A domain name (optional, for HTTPS on Vault)
- [ ] Basic Linux/SSH knowledge

---

## Step 1: Launch EC2 Instance for Vault

### Create IAM Role for EC2 first:

1. AWS Console → IAM → Roles → Create Role
2. Trusted entity: **AWS Service** → **EC2**
3. Attach policy: `AdministratorAccess`
4. Role name: `Vault-EC2-Role`
5. Create Role

### Launch EC2:

1. EC2 → Launch Instance
2. Name: `vault-server`
3. AMI: Amazon Linux 2023
4. Instance type: `t3.small` (minimum for Vault)
5. Key pair: Create or select existing
6. **IAM instance profile: Select `Vault-EC2-Role`** (this gives Vault access to AWS without keys)
7. Security Group:
   - SSH (22) — your IP only
   - Custom TCP (8200) — your IP + GitHub Actions IPs (for Vault API)
8. Storage: 20 GB gp3
9. Launch

### Note the public IP or Elastic IP of this instance.

> **Why IAM Role?** Vault uses the EC2 instance role to generate temporary AWS credentials. No access keys are stored anywhere — not in Vault, not in GitHub, not on disk.

---

## Step 2: Install Vault on EC2

SSH into the instance and run:

```bash
# SSH into the instance
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Install Vault
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install vault

# Verify installation
vault --version
```

---

## Step 3: Configure Vault Server

```bash
# Create Vault config directory
sudo mkdir -p /etc/vault.d
sudo mkdir -p /opt/vault/data

# Create Vault config file
sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOF
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
  # For production: Enable TLS with a real certificate
  # tls_cert_file = "/etc/vault.d/tls/vault-cert.pem"
  # tls_key_file  = "/etc/vault.d/tls/vault-key.pem"
}

api_addr = "http://YOUR_EC2_PUBLIC_IP:8200"

ui = true
EOF

# Set permissions
sudo chown -R vault:vault /etc/vault.d /opt/vault
```

---

## Step 4: Start Vault as a Service

```bash
# Create systemd service
sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF
[Unit]
Description=HashiCorp Vault
After=network.target

[Service]
User=vault
Group=vault
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Start Vault
sudo systemctl enable vault
sudo systemctl start vault
sudo systemctl status vault
```

---

## Step 5: Initialize and Unseal Vault

```bash
# Set Vault address
export VAULT_ADDR="http://127.0.0.1:8200"

# Initialize Vault (SAVE THESE KEYS SECURELY!)
vault operator init -key-shares=5 -key-threshold=3

# Output will show:
# Unseal Key 1: xxxxx
# Unseal Key 2: xxxxx
# Unseal Key 3: xxxxx
# Unseal Key 4: xxxxx
# Unseal Key 5: xxxxx
# Initial Root Token: hvs.xxxxx
#
# SAVE THESE SOMEWHERE SAFE (password manager, not in git!)

# Unseal Vault (need 3 of 5 keys)
vault operator unseal <KEY_1>
vault operator unseal <KEY_2>
vault operator unseal <KEY_3>

# Login with root token
vault login <ROOT_TOKEN>
```

---

## Step 6: Enable AWS Secrets Engine

This tells Vault how to generate temporary AWS credentials.
Vault uses the EC2 instance's IAM Role (attached in Step 1) — no access keys needed.

```bash
# Enable the AWS secrets engine
vault secrets enable aws

# Configure Vault to use the EC2 instance role (NO access keys!)
# Vault automatically picks up credentials from the IAM Role attached to the EC2
# Replace YOUR_REGION with your actual AWS region (e.g., ap-south-1, us-east-1)
vault write aws/config/root \
  region=YOUR_REGION

# Create a role that Terraform will use
# This role generates STS credentials with AdministratorAccess
vault write aws/roles/terraform-role \
  credential_type=iam_user \
  policy_arns=arn:aws:iam::aws:policy/AdministratorAccess \
  default_ttl=1h \
  max_ttl=2h

# Test: Generate temporary credentials
vault read aws/creds/terraform-role
# Output:
# Key            Value
# access_key     AKIA...
# secret_key     xxxxx
# security_token xxxxx
# ttl            1h
```

> **Important:** The EC2 instance must have an IAM Role attached with `AdministratorAccess` (or permissions to create STS credentials). This is done in Step 1 when launching the EC2 instance.

---

## Step 7: Enable JWT Auth for GitHub Actions

This tells Vault to trust GitHub Actions OIDC tokens.

```bash
# Enable JWT auth method
vault auth enable jwt

# Configure JWT auth to trust GitHub's OIDC provider
vault write auth/jwt/config \
  bound_issuer="https://token.actions.githubusercontent.com" \
  oidc_discovery_url="https://token.actions.githubusercontent.com"

# Create a policy for GitHub Actions (what it can access in Vault)
vault policy write github-actions-policy - <<EOF
# Allow reading AWS credentials
path "aws/creds/terraform-role" {
  capabilities = ["read"]
}

# Allow reading AWS STS credentials
path "aws/sts/terraform-role" {
  capabilities = ["read"]
}
EOF

# Create a role that maps GitHub repos to Vault policies
vault write auth/jwt/role/github-actions-role \
  role_type="jwt" \
  bound_audiences="sigstore" \
  bound_claims_type="glob" \
  bound_claims="/repository=arumullayaswanth/DevSecOps-Zero-to-Hero" \
  user_claim="repository" \
  policies="github-actions-policy" \
  ttl=1h

# IMPORTANT: Change 'arumullayaswanth/DevSecOps-Zero-to-Hero' to YOUR repo
```

---

## Step 8: Add GitHub Variables

Go to GitHub → Repo → Settings → Secrets and variables → Actions → Variables tab

Only add these **mandatory** variables (everything else has defaults in the code):

| Variable | Value | Why it's needed |
|----------|-------|-----------------|
| `VAULT_ADDR` | `http://YOUR_EC2_PUBLIC_IP:8200` | Where Vault is running |
| `VAULT_ROLE` | `github-actions-role` | Vault role for JWT auth |
| `AWS_REGION` | Your region (e.g., `ap-south-1`) | Where to create infrastructure |
| `TF_STATE_BUCKET` | Your S3 bucket name | Where state is stored |
| `TF_LOCK_TABLE` | `terraform-state-lock` | DynamoDB lock table |

**What's NOT in GitHub Variables (set directly in code):**
- `TF_WORKING_DIR` = `Episode-07-IaC-Security/terraform-vault` (in workflow yml)
- `TF_STATE_KEY` = `vault/terraform.tfstate` (in backend.tf)
- `allowed_ssh_cidr` = `0.0.0.0/0` (default in variables.tf — open for practice)
- `environment` = `production` (default in variables.tf)
- `vpc_cidr` = `10.0.0.0/16` (default in variables.tf)
- `instance_type` = `t3.micro` (default in variables.tf)
- `vault_aws_role` = `terraform-role` (default in variables.tf)

---

## Step 9: Test the Workflow

```bash
# Create a branch
git checkout -b test-vault-infra

# Push and create PR
git add .
git commit -m "Test Vault-based Terraform"
git push -u origin test-vault-infra

# Or manually trigger:
# GitHub → Actions → "Terraform with Vault" → Run workflow → Select env + action
```

---

## Step 10: Verify It Works

1. Go to GitHub Actions → Check the workflow run
2. It should:
   - Authenticate to Vault via JWT ✅
   - Get temporary AWS credentials from Vault ✅
   - Run terraform plan/apply ✅
   - Credentials expire after 1 hour ✅

---

## Security Checklist for Vault on EC2

- [ ] Use TLS (HTTPS) for Vault in production (Let's Encrypt or ACM)
- [ ] Restrict security group to only GitHub Actions IPs and your IP
- [ ] Store unseal keys in separate secure locations (not all in one place)
- [ ] Enable Vault audit logging (`vault audit enable file file_path=/var/log/vault-audit.log`)
- [ ] Use auto-unseal with AWS KMS (so Vault auto-unseals on restart)
- [ ] Set short TTLs for AWS credentials (1h max)
- [ ] Restrict the JWT role to only your specific repository
- [ ] Regular Vault backups (`vault operator raft snapshot save`)

---

## Troubleshooting

### Error: "permission denied" from Vault
- Check the policy attached to `github-actions-role`
- Verify the `bound_claims` matches your exact repo name

### Error: "Vault is sealed"
- You need to unseal Vault after every restart
- Use auto-unseal with KMS to avoid this

### Error: "no credentials found"
- Check that AWS secrets engine is enabled: `vault secrets list`
- Check the role exists: `vault read aws/roles/terraform-role`

### Error: "JWT validation failed"
- Check that `bound_audiences` matches (should be `sigstore`)
- Check that `oidc_discovery_url` is correct

---

## Comparison: OIDC vs Vault

| | OIDC (terraform-OIDC) | Vault (terraform-vault) |
|---|---|---|
| Setup time | 30 minutes | 2-3 hours |
| Infrastructure needed | None (AWS only) | EC2 instance running Vault |
| Maintenance | Zero | Vault updates, unsealing, backups |
| Cost | Free | EC2 cost (~$15/month for t3.small) |
| Security level | High | Very High |
| Best for | Single cloud, small team | Multi-cloud, enterprise, compliance |
| When to use | Most projects | Regulated industries, multi-team |
