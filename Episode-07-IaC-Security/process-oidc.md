# Step-by-Step Process: Terraform + GitHub Actions + OIDC

## What We Are Building

![Architecture OIDC](images/architecture%20oidc.jpg)

---

## Prerequisites (What You Need Before Starting)

- [ ] AWS Account (free tier works)
- [ ] GitHub Account
- [ ] GitHub Repository (your DevSecOps-Zero-to-Hero repo)


---

## Step 1: Create S3 Bucket for Terraform State

Terraform needs a place to store its state file remotely. We use S3.

### Go to AWS Console:

1. Open AWS Console → Search "S3" → Click "Create bucket"
2. Bucket name: `devsecops-terraform-state-0001` (must be globally unique, change if taken)
3. Region: `ap-south-1` (Mumbai) or your preferred region
4. Enable "Bucket Versioning" → Enabled
5. Enable "Default encryption" → SSE-S3 (AES-256)
6. Block all public access → ✅ Keep all checked
7. Click "Create bucket"

---

## Step 2: Create DynamoDB Table for State Locking

This prevents two people from running `terraform apply` at the same time.

### Go to AWS Console:

1. Open AWS Console → Search "DynamoDB" → Click "Create table"
2. Table name: `terraform-state-lock`
3. Partition key: `LockID` (type: String)
4. Leave everything else default
5. Click "Create table"

---

## Step 3: Create OIDC Identity Provider in AWS

This tells AWS: "I trust GitHub. When GitHub Actions says it's from my repo, believe it."

### Go to AWS Console:

1. Open AWS Console → Search "IAM" → Click "Identity providers" (left sidebar)
2. Click "Add provider"
3. Provider type: **OpenID Connect**
4. Provider URL: `https://token.actions.githubusercontent.com`
5. Click "Get thumbprint"
6. Audience: `sts.amazonaws.com`
7. Click "Add provider"

---

## Step 4: Create IAM Role for GitHub Actions

This role gives GitHub Actions permission to create infrastructure. It trusts ONLY your specific repo.

### Go to AWS Console:

1. Open AWS Console → Search "IAM" → Click "Roles" → "Create role"
2. Trusted entity type: **Web identity**
3. Identity provider: Select `token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Click "Next"
6. Attach permissions: Select `AdministratorAccess` (for demo; use custom policy in production)
7. Click "Next"
8. Role name: `GitHubActions-Terraform-Role`
9. Click "Create role"

### Now edit the trust policy to restrict to YOUR repo:

1. Go to IAM → Roles → Click `GitHubActions-Terraform-Role`
2. Click "Trust relationships" tab → "Edit trust policy"
3. Replace with this (change `arumullayaswanth` to YOUR GitHub username):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:arumullayaswanth/DevSecOps-Zero-to-Hero:*"
        }
      }
    }
  ]
}
```

4. Replace `YOUR_ACCOUNT_ID` with your actual AWS account ID (12-digit number)
5. Replace `arumullayaswanth/DevSecOps-Zero-to-Hero` with your GitHub username/repo
6. Click "Update policy"

### How to find your AWS Account ID:

```bash
aws sts get-caller-identity --query "Account" --output text
```

Or: AWS Console → Click your username (top right) → Account ID is shown

---

## Step 5: Copy the Role ARN

1. Go to IAM → Roles → Click `GitHubActions-Terraform-Role`
2. Copy the "ARN" at the top. It looks like:
   ```
   arn:aws:iam::123456789012:role/GitHubActions-Terraform-Role
   ```
3. Save this — you need it in Step 6

---

## Step 6: Add Variables in GitHub Repository Settings

Instead of hardcoding values in the workflow file, we store them in GitHub Variables.

1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click the **"Variables"** tab (not Secrets)
3. Click **"New repository variable"** and add these 3 variables:

| Variable Name | Value | Example |
|---|---|---|
| `AWS_REGION` | Your AWS region | `ap-south-1` |
| `AWS_ROLE_ARN` | The role ARN from Step 5 | `arn:aws:iam::123456789012:role/GitHubActions-Terraform-Role` |
| `TF_STATE_BUCKET` | S3 bucket name from Step 1 | `devsecops-terraform-state-0001` |
| `TF_LOCK_TABLE` | DynamoDB table name from Step 2 | `terraform-state-lock` |

**What's NOT in GitHub Variables (set directly in code):**
- `TF_WORKING_DIR` = `Episode-07-IaC-Security/terraform-OIDC` (in workflow yml)
- `TF_STATE_KEY` = `production/terraform.tfstate` (in backend.tf)

### Why Variables and NOT Secrets?

- **Variables** (`vars.XX`) = For non-sensitive config (region, paths, role ARN)
- **Secrets** (`secrets.XX`) = For sensitive data (passwords, tokens)

The Role ARN is not a secret — it's just a resource identifier. Anyone can see it but they can't use it without being authenticated from your specific repo via OIDC.

### Nothing is hardcoded in the workflow file!

The workflow uses `${{ vars.AWS_ROLE_ARN }}`, `${{ vars.AWS_REGION }}`, etc. — all values come from GitHub Variables. You never need to edit the `.yml` file to change configuration.

---

## Step 7: Push Code and Create a Pull Request

```bash
# Create a new branch
git checkout -b add-terraform-infra

# Stage all changes
git add .

# Commit
git commit -m "Add Terraform infrastructure with OIDC and Checkov"

# Push to GitHub
git push -u origin add-terraform-infra
```

Now go to GitHub:
1. You'll see a banner "Compare & pull request" → Click it
2. Title: "Add Terraform infrastructure"
3. Click "Create pull request"

---

## Step 8: Watch GitHub Actions Run Automatically

Once you create the PR, GitHub Actions will automatically:

1. ✅ Run Checkov security scan on your Terraform files
2. ✅ Run `terraform init`
3. ✅ Run `terraform fmt -check`
4. ✅ Run `terraform validate`
5. ✅ Run `terraform plan`
6. ✅ Post the plan output as a comment on your PR

You can see this at: GitHub → Your repo → Actions tab

---

## Step 9: Review and Merge the PR

1. Look at the plan in the PR comment — it shows what will be created
2. If everything looks good, click "Merge pull request"
3. After merge, GitHub Actions will automatically run `terraform apply`
4. Infrastructure is now created on AWS!

---

## Step 10: Verify Infrastructure Was Created

```bash
# Check in AWS Console
# Go to: EC2 → Instances → You should see your new instance
# Go to: VPC → Your VPCs → You should see the new VPC
# Go to: S3 → You should see the app-data bucket
```

---

## Step 11: Destroy Infrastructure (When You're Done)

Two options:

### Option A: Manual trigger from GitHub Actions

1. Go to GitHub → Your repo → Actions tab
2. Click "Terraform Infrastructure" workflow on the left
3. Click "Run workflow" button (top right)
4. Select action: `destroy`
5. Click "Run workflow"
6. GitHub Actions will run `terraform destroy` and delete everything

### Option B: Create a PR that removes the resources

1. Delete or comment out resources in `main.tf`
2. Push and create PR
3. Plan will show resources being destroyed
4. Merge → `terraform apply` removes them

---

## Summary: What You Configured

| What | Where | Purpose |
|------|-------|---------|
| S3 Bucket | AWS | Stores Terraform state (encrypted, versioned) |
| DynamoDB Table | AWS | Locks state during apply (prevents conflicts) |
| OIDC Provider | AWS IAM | Trusts GitHub as identity provider |
| IAM Role | AWS IAM | GitHub Actions assumes this role (no keys!) |
| terraform-oidc.yml | `.github/workflows/` | Automates plan/apply/destroy |
| backend.tf | `terraform-OIDC/` | Points Terraform to S3 state |
| GitHub Variables | GitHub Settings | Stores all config (no hardcoding in files) |

---

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"
- Your trust policy is wrong. Check Step 4 — make sure repo name and account ID are correct.

### Error: "No valid credential sources found"
- The role ARN in the workflow is wrong. Check Step 6.

### Error: "S3 bucket does not exist"
- You haven't created the S3 bucket yet. Go back to Step 1.

### Error: "DynamoDB table does not exist"
- You haven't created the DynamoDB table. Go back to Step 2.

### Error: "terraform plan shows errors"
- Run `terraform validate` locally first to check syntax.

### Checkov fails the PR
- Checkov found security issues. Read the output — it tells you exactly what to fix.

---

## Security: Why This Is Better Than Access Keys

| Access Keys (Old Way) | OIDC (Our Way) |
|----------------------|----------------|
| Keys stored in GitHub Secrets forever | No keys stored anywhere |
| If leaked, attacker has permanent access | Tokens expire in 1 hour |
| Same key used for all runs | Fresh token generated every run |
| Manual rotation needed | No rotation needed (automatic) |
| Any workflow in repo can use the key | Only specific repo + branch can assume role |
