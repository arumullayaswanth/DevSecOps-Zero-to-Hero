

# 🎬 Episode 04 — DevSecOps for Git (FULL HANDS-ON DEMO)

---

# 🧩 What We Are Building

We will secure Git step by step using:

* `.gitignore`
* **Pre-commit hook**
* **Gitleaks**
* **GitHub Actions**
* **Branch Protection**
* **CODEOWNERS**
* **Dependabot**

---

# 🖥️ STEP 1 — Create Project

> Let’s start by creating a simple project.

```bash
mkdir devsecops-git-demo
cd devsecops-git-demo
git init
```

---

# 🖥️ STEP 2 — Create Sample App

```bash
touch app.py
```

Add:

```python
print("DevSecOps Git Security Demo")
```

---

# 🖥️ STEP 3 — Create Secret (IMPORTANT DEMO)

```bash
touch secret.txt
```

Add:

```
AWS_SECRET_ACCESS_KEY=MY_SUPER_SECRET_KEY
```


> This simulates a real mistake developers make.

---

# 🖥️ STEP 4 — Use .gitignore (Prevent Secret)

```bash
touch .gitignore
```

Add:

```
secret.txt
.env
*.pem
```

---

### Commit

```bash
git add .
git commit -m "initial commit"
```


> Now secret.txt is ignored and won’t be pushed.

---

# 🖥️ STEP 5 — Install Gitleaks

### Mac

```bash
brew install gitleaks
```

### Linux

```bash
sudo apt install gitleaks
```
### 🔐 Install Gitleaks (Windows)

#### Using winget (recommended)

```powershell
winget install --id Gitleaks.Gitleaks -e
```

#### Verify Installation

```powershell
gitleaks version
```

#### If `gitleaks` is not recognized

Run the following:

```powershell
dir "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
```

If `gitleaks.exe` exists, add it to PATH:

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  $env:Path + ";$env:LOCALAPPDATA\Microsoft\WinGet\Links",
  "User"
)
```

Restart PowerShell and verify again:

```powershell
gitleaks version
```

---

# 🖥️ STEP 6 — Run Gitleaks Scan

```bash
gitleaks detect
```

##### Scan a Git Repository

```powershell
gitleaks detect --source <repo-path> --report-format json --report-path report.json
```
#### Run Gitleaks Scan

```powershell
gitleaks detect --source . -v
```

> Gitleaks scans the repository and detects secrets automatically.


---

# 🖥️ STEP 7 — Pre-Commit Hook (BLOCK SECRETS) 

https://pre-commit.com/#install

> Now let’s stop secrets before they even enter Git.

---

### Create hook

```bash
vim .git/hooks/pre-commit
```

Paste:

```bash
#!/bin/sh

echo "Running Gitleaks..."

gitleaks detect --source . --no-git

if [ $? -ne 0 ]; then
  echo "❌ Secret detected! Commit blocked."
  exit 1
fi
```

---

### Make executable

```bash
chmod +x .git/hooks/pre-commit
```

---

### Test it

Remove `.gitignore` entry temporarily and try:

```bash
git add secret.txt
git commit -m "testing secret"
```


> Now the commit is blocked — this is real DevSecOps prevention.

---

# 🖥️ STEP 8 — Push to GitHub


Then:

```bash
git remote add origin https://github.com/YOUR_USERNAME/devsecops-git-demo.git
git branch -M main
git push -u origin main
```

---

# 🖥️ STEP 9 — GitHub Actions (AUTO SCAN)

> Now let’s automate security checks.

---

### Create workflow

```bash
mkdir -p .github/workflows
nano .github/workflows/gitleaks.yml
```

---

### Paste:

```yaml
name: Gitleaks Scan

on: [push]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
```

---

### Push again

```bash
git add .
git commit -m "add gitleaks pipeline"
git push
```



---

# 🖥️ STEP 10 — Branch Protection (MANDATORY REVIEWS)

 Go to:

GitHub → Settings → Branches → Add Rule

Enable:

* Require pull request
* Require approvals
* Restrict direct push


> Now no one can directly push to main branch.

---

# 🖥️ STEP 11 — CODEOWNERS


> Now we define who reviews code.

---

### Create:

```bash
mkdir .github
nano .github/CODEOWNERS
```

---

### Add:

```
* YOUR_GITHUB_USERNAME
```

---



> Now every change must be reviewed by this user.

---

# 🖥️ STEP 12 — DEPENDABOT


> Now let’s secure dependencies automatically.

---

### Create:

```bash
nano .github/dependabot.yml
```

---

### Paste:

```yaml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "daily"
```

---


> Dependabot will create pull requests for vulnerable libraries.

---

# 🧠 FINAL FLOW (Explain This)


```
Developer → Git (Pre-commit)
        ↓
GitHub → Actions Scan
        ↓
Pull Request → Review
        ↓
Secure Merge
```

---



