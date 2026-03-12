DevSecOps for Git
Contents
.gitignore
Native Git Pre-Commit Hooks (Custom Scripts)
Block commits with Gitleaks
Gitleaks -> Repository & History Scanning
Gitleaks in GitHub Actions
Branch Protection Rules
RBAC
Mandatory Reviews
CODEOWNERS
Dependabot
.gitignore — First Line of Defense
Purpose
Prevent sensitive files from ever being tracked by Git.

Common Security Files to Ignore
.env
.env.*
*.pem
*.key
id_rsa
terraform.tfstate
.terraform/
node_modules/
dist/
Demo
echo "AWS_SECRET_ACCESS_KEY=123" > .env
git status
Add .gitignore:

echo ".env" >> .gitignore
git status
✅ File is no longer tracked.

⚠️ .gitignore does NOT protect secrets already committed.

Native Git Pre-Commit Hooks (Custom Script)
What This Is
A pre-commit hook is a script located at:

.git/hooks/pre-commit
Git executes it automatically before every commit.

Exit Codes
Code	Result
0	Commit allowed
≠0	Commit blocked
Demo — Minimal Native Secret Detector
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "🔍 Running native pre-commit hook..."

if git diff --cached | grep -i "secret"; then
  echo "❌ Secret detected. Commit blocked."
  exit 1
fi

echo "✅ Commit passed security checks."
exit 0
EOF
Make executable:

chmod +x .git/hooks/pre-commit
Test:

echo "my_secret=123" > test.txt
git add test.txt
git commit -m "test commit"
❌ Commit blocked.

Gitleaks — Blocking Commits (Native Hook)
Replace Pre-Commit Hook with Gitleaks
Install pre-commit from https://pre-commit.com/#install

Create a .pre-commit-config.yaml file at the root of your repository with the following content:

repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.24.2
    hooks:
      - id: gitleaks
Auto-update the config to the latest repos' versions by executing pre-commit autoupdate

Install with pre-commit install

Now you're all set!

Demo — Block a Secret Commit
echo "AWS_SECRET_ACCESS_KEY=AKIA123456789" > secrets.env
git add secrets.env
git commit -m "adding secrets"
❌ Commit blocked.

Gitleaks — Repository & History Scanning
Create a custom rules file - custom-rules.toml
[[rules]]
id = "generic-password"
description = "Detect any PASSWORD assignment"
regex = '''(?i)password\s*=\s*["'][^"']+["']'''
tags = ["password", "custom"]
Run the gitleaks command
gitleaks detect --config custom-rules.toml

Gitleaks in GitHub Actions
GitHub Action
Check out the official Gitleaks GitHub Action

name: gitleaks
on: [pull_request, push, workflow_dispatch]
jobs:
  scan:
    name: gitleaks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE}} # Only required for Organizations, not personal accounts.
Branch Protection Rules
Enforce:

No direct pushes to main
Required pull requests
Required status checks
No force pushes
RBAC — Least Privilege
Role	Permissions
Admin	Repo settings
Maintainer	Merge PRs
Developer	PR only
Auditor	Read-only
Mandatory Reviews
Best practices:

Minimum 1–2 reviewers
Code owners for sensitive paths
Security review for auth, infra, CI
CODEOWNERS
/.github/ @security-team
/terraform/ @cloud-team
Dependabot
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
