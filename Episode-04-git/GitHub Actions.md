# ⚙️ GitHub Actions — Gitleaks Scan

This project uses **GitHub Actions** to automatically scan for secrets using **Gitleaks** on every push and pull request.

---

## 🚀 Step 1: Create Workflow File

Create the following file:

```bash
mkdir -p .github/workflows
vim .github/workflows/gitleaks.yml
```

---

## 🧩 Step 2: Add Workflow Configuration

```yaml
name: Secret Scan (Gitleaks)

on:
  push:
    branches:
      - "**"
  pull_request:
  workflow_dispatch:

jobs:
  secret-detection:
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Clone Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: 🔍 Run Gitleaks Scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          args: detect --verbose --redact --exit-code 1
```

---

## ▶️ Step 3: Commit & Push

```bash
git add .github/workflows/gitleaks.yml
git commit -m "add gitleaks github action"
git push
```

---

## 🔒 What Happens Now?

On every:

* 📤 Push event
* 🔀 Pull Request
* 📤 Manual trigger (workflow_dispatch)
GitHub will:

* 🔍 Run Gitleaks scan
* ❌ Fail the workflow if secrets are found
* ✅ Pass if no issues are detected

---

## 🧪 How to Test

1. Add a fake secret:

   ```txt
   AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
   ```

2. Commit & push:

   ```bash
   git add .
   git commit -m "test secret"
   git push
   ```

👉 Expected result:

* ❌ Workflow fails in GitHub Actions

---

## 📊 Where to See Results

* Go to your repository on GitHub
* Click on **Actions** tab
* Open the latest workflow run

---

## 🧠 Why Use GitHub Actions?

| Feature            | Benefit               |
| ------------------ | --------------------- |
| Automated scanning | No manual effort      |
| CI/CD integration  | Runs on every push    |
| Team safety        | Prevents leaks in PRs |
| Visibility         | Reports in GitHub UI  |

---

## 🚀 Final Thought

> Even if someone bypasses local hooks, GitHub Actions ensures secrets never make it into your repository.

