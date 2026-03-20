# Pre-Commit Hook (BLOCK SECRETS) 

#### Install pre-commit

* 🐧 [Linux](https://pre-commit.com/#install)
* 🪟 Windows (PowerShell):

```powershell
# Install using pip
python -m pip install pre-commit

# Verify installation
pre-commit --version

# Install pre-commit hooks in your repo
pre-commit install
```
* 🍎 macOS:

  ```bash
  brew install pre-commit
  ```
> Now let’s stop secrets before they even enter Git.
---

### Create hook
## ## 🔒 Pre-Commit Hook: Secret Detection

This project uses a custom Git pre-commit hook to prevent accidental commits of sensitive information.

### ⚙️ How It Works

* The hook scans **staged changes** using:

  ```bash
  git diff --cached
  ```
* It searches for the keyword **"secret"** (case-insensitive).
* If a match is found:

  * ❌ The commit is blocked
* If no match is found:

  * ✅ The commit proceeds normally

### 🚫 Blocking Condition

Any staged content containing the word:

```
secret
```

will trigger:

```
Commit aborted
```

```bash
vim .git/hooks/pre-commit.sh
```

Paste:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "🔍 Checking staged changes for sensitive keywords..."

staged_changes=$(git diff --cached)

echo "$staged_changes" | grep -iq "secret"
found=$?

if [ $found -eq 0 ]; then
  echo "❌ Potential secret found. Commit aborted."
  exit 1
fi

echo "✅ No sensitive content detected. Proceeding with commit."
exit 0
EOF
```


### Make executable

```bash
chmod +x .git/hooks/pre-commit
```

### Test it

Remove `.gitignore` entry temporarily and try:
> Create some text files Or create some code based and you can hardcoded Secrets It will detect

```bash
git add secret.txt
git commit -m "testing secret"
```

> Now the commit is blocked — this is real DevSecOps prevention.

These will NOT be blocked:
```bash
API_KEY=123456abcdef
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxx
password=admin123
```
👉 Because none of these contain the word "secret"
