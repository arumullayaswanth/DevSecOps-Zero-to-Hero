# 🤖 Dependabot (Automated Dependency Updates)

Dependabot helps keep your project secure by automatically updating dependencies and fixing known vulnerabilities.

---

## 🚀 Step 1: Create Configuration File

Create the following file:

```bash id="9c3z9c"
mkdir -p .github
vim .github/dependabot.yml
```

---

## 🧩 Step 2: Add Configuration

```yaml id="x4t8zx"
version: 2

updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## ⚙️ How It Works

* Dependabot scans your project for outdated dependencies
* Automatically creates **pull requests** to update them
* Includes **security fixes** for vulnerable packages

---

## 🔄 Update Schedule

| Interval | Meaning             |
| -------- | ------------------- |
| daily    | Checks every day    |
| weekly   | Checks once a week  |
| monthly  | Checks once a month |

---

## 🔍 What It Detects

* Outdated libraries
* Security vulnerabilities (CVEs)
* Version conflicts

---

## 📥 What Happens Next?

* 🤖 Dependabot creates a PR
* 👥 Reviewers (CODEOWNERS) are assigned
* 🔍 GitHub Actions (Gitleaks) runs
* 🔒 Branch protection enforces checks

---

## 🧠 Why Use Dependabot?

| Feature           | Benefit                  |
| ----------------- | ------------------------ |
| Auto updates      | Saves time               |
| Security patches  | Fix vulnerabilities fast |
| PR-based workflow | Safe updates             |
| Integration       | Works with CI/CD         |

---

## 🔐 Best Practice

* Combine with:

  * 🔒 Branch Protection
  * 👥 CODEOWNERS
  * ⚙️ GitHub Actions

* Enable:

  * ✔️ Auto-merge (optional)
  * ✔️ Required reviews

---

## 📊 Summary

| Feature        | Description        |
| -------------- | ------------------ |
| Tool           | Dependabot         |
| Purpose        | Dependency updates |
| Trigger        | Scheduled          |
| Output         | Pull Requests      |
| Security level | 🔥 High            |

---

## 🚀 Final Thought

> Dependabot ensures your dependencies stay secure — automatically and continuously.
