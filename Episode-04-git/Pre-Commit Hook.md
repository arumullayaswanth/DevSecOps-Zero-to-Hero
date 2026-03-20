# 🔒 Pre-Commit Hook (Block Secrets)

This project uses a **custom Git pre-commit hook** to prevent accidental commits of sensitive information using a simple keyword-based check.

---

## 🚀 Step 1: Create the Hook

Create the pre-commit hook file:

```bash
vim .git/hooks/pre-commit
```

## 🧩 Step 2: Add the Script

Paste the following code:

```bash
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
```

## 🔧 Step 3: Make It Executable

```bash
chmod +x .git/hooks/pre-commit
```

---

## ⚙️ How It Works

* The hook scans **staged changes** using:

  ```bash
  git diff --cached
  ```
* It searches for the keyword **"secret"** (case-insensitive)
* Based on the result:

  * ❌ If found → Commit is blocked
  * ✅ If not found → Commit proceeds

---

## 🚫 Blocking Condition

Any staged content containing:

```
secret
```

will result in:

```
Commit aborted
```

---

## 🧪 Step 4: Test the Hook

### 📁 Create a test file

```bash
vim secret.txt
```

### ✏️ Add content

```txt
this is a secret key
```

### ➕ Stage the file

```bash
git add secret.txt
```

### 🚫 Try to commit

```bash
git commit -m "testing secret"
```

👉 Expected result:

* ❌ Commit is blocked

---

## ⚠️ Limitations

This hook only checks for the keyword **"secret"**.

The following will **NOT be blocked**:

```bash
API_KEY=123456abcdef
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxx
password=admin123
```

👉 Because they do not contain the word `"secret"`

---

## 🧠 Summary

| Feature              | Behavior            |
| -------------------- | ------------------- |
| Scan scope           | Staged changes only |
| Detection type       | Keyword-based       |
| Blocks commit        | Yes                 |
| Detects real secrets | ❌ No                |
| Security level       | Basic               |

---

## 🚀 Final Thought

> This is a simple first step toward DevSecOps — but for real security, use tools like **Gitleaks with pre-commit**.
