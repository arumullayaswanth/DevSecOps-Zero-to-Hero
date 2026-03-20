# 🔐 Gitleaks Setup & Usage

Gitleaks is a powerful tool used to detect hardcoded secrets such as API keys, tokens, and passwords in your codebase.

---

## 🚀 Step 1: Install Gitleaks

### 🍎 macOS

```bash
brew install gitleaks
```

### 🐧 Linux

```bash
sudo apt install gitleaks
```

### 🪟 Windows (PowerShell)

#### Using winget (Recommended)

```powershell
winget install --id Gitleaks.Gitleaks -e
```

---

## ✅ Step 2: Verify Installation

```bash
gitleaks version
```

---

## ⚠️ If `gitleaks` is Not Recognized (Windows)

Check if the executable exists:

```powershell
dir "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
```

If `gitleaks.exe` is listed, add it to your PATH:

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  $env:Path + ";$env:LOCALAPPDATA\Microsoft\WinGet\Links",
  "User"
)
```

🔁 Restart PowerShell and verify again:

```powershell
gitleaks version
```

---

## 🔍 Step 3: Run Gitleaks Scan

### 📁 Scan Current Repository

```bash
gitleaks detect
```

---

### 📂 Scan Specific Path

```bash
gitleaks detect --source <repo-path>
```

---

### 📄 Generate Report (JSON)

```bash
gitleaks detect --source <repo-path> --report-format json --report-path report.json
```

---

### 🔎 Verbose Scan

```bash
gitleaks detect --source . -v
```

---

## 🔒 What Gitleaks Does

* Scans your codebase for sensitive data
* Detects:

  * API keys
  * Tokens
  * Passwords
  * Private keys
* Helps prevent accidental secret leaks

---

## 🧠 Summary

| Feature        | Description          |
| -------------- | -------------------- |
| Scan type      | Static code analysis |
| Detection      | Pattern-based        |
| Output         | CLI / JSON reports   |
| Security level | High                 |

---

## 🚀 Final Thought

> Gitleaks helps you catch secrets before they become security risks — integrate it with pre-commit for maximum protection.
