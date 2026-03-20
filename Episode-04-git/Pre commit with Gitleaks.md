# 🔒 Pre-commit Framework with Gitleaks

Prevent sensitive data like API keys, tokens, and passwords from being committed to your repository.

---

## 🚀 Step 1: Install `pre-commit`

### 🐧 Linux

👉 [Install Guide](https://pre-commit.com/#install)

### 🪟 Windows (PowerShell)

```powershell
# Install pre-commit
python -m pip install pre-commit

# Verify installation
pre-commit --version
```

### 🍎 macOS

```bash
brew install pre-commit
```

---

## ⚙️ Step 2: Configure Gitleaks

### 📁 Create config file

```bash
vim .pre-commit-config.yaml
```

### 🧩 Add configuration

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks
        args: ["--no-git"]
```

---

## 🔧 Step 3: Install Git Hook

```bash
pre-commit install
```

👉 Optional (run manually on all files):

```bash
pre-commit run --all-files
```

---

## 🔒 What Happens Now?

On every commit:

* 🔍 Gitleaks scans your code
* ❌ If secrets are detected → Commit is blocked
* ✅ If no issues → Commit is allowed

---

## 🧪 Step 4: Test the Setup

### 📁 Create a test file

```bash
vim app.py
```

### ✏️ Add a fake secret

```python
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
```

### ➕ Stage the file

```bash
git add app.py
```

### 🚫 Try to commit

```bash
git commit -m "test secret detection"
```

👉 Expected result:

* ❌ Commit should be blocked

---

### ✅ Fix and retry

Remove the secret and commit again:

```bash
git add app.py
git commit -m "clean commit"
```

👉 Expected result:

* ✅ Commit succeeds

---

## 🧠 Why Use Gitleaks + Pre-commit?

| Feature             | Basic Script | Gitleaks + Pre-commit |
| ------------------- | ------------ | --------------------- |
| Detect real secrets | ❌            | ✅                     |
| Detect API keys     | ❌            | ✅                     |
| Detect tokens       | ❌            | ✅                     |
| Accuracy            | Low          | High                  |
| Automation          | Manual       | Automatic             |

---

## 💡 Summary

* Prevents accidental secret leaks
* Runs automatically before every commit
* Uses industry-standard detection rules

---

## 🚀 Final Thought

> Now let’s stop secrets before they even enter Git.
