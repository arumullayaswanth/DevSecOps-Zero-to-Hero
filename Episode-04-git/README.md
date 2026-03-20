# Episode 04 — DevSecOps for Git (Topics)

## 🔐 1. .gitignore

Prevent sensitive and unnecessary files from being tracked by Git.

* Avoid committing `.env`, secrets, and system files
* Keeps the repository clean and secure

---

## 🔍 2. Pre-Commit Hook (Basic)

👉 [View Documentation](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero/blob/c13c228b30b8e2d9438d1f69aabc73e40c5274af/Episode-04-git/Pre-Commit%20Hook.md)

* Custom Git hook to scan staged changes
* Blocks commits based on keyword detection
* First level of local security

---

## 🔒 3. Pre-Commit Framework with Gitleaks

👉 [View Documentation](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero/blob/c13c228b30b8e2d9438d1f69aabc73e40c5274af/Episode-04-git/Pre%20commit%20with%20Gitleaks.md)

* Uses `pre-commit` framework
* Integrates **Gitleaks** for advanced secret detection
* Automatically scans before every commit

---

## 🛡️ 4. Gitleaks (Repository Scan)

👉 [View Documentation](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero/blob/c13c228b30b8e2d9438d1f69aabc73e40c5274af/Episode-04-git/Gitleaks%20rep%20Scan%20.md)

* Scans entire repository for secrets
* Detects:

  * API keys
  * Tokens
  * Passwords
* Can generate reports

---

## ⚙️ 5. GitHub Actions (CI Security)

👉 [View Documentation](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero/blob/c13c228b30b8e2d9438d1f69aabc73e40c5274af/Episode-04-git/GitHub%20Actions.md)

* Automates Gitleaks scanning in CI/CD
* Runs on push and pull requests
* Blocks insecure code before merging

---

## 👥 6. Role-Based Access Control (RBAC)

* Defines who can access and modify the repository
* Controls permissions for:

  * Developers
  * Reviewers
  * Admins
* Improves security and governance

---

## 🔐 7. Branch Protection

👉 [View Documentation](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero/blob/c13c228b30b8e2d9438d1f69aabc73e40c5274af/Episode-04-git/Branch%20Protection%20.md)

* Prevents direct commits to protected branches
* Requires:

  * Pull requests
  * Status checks
  * Reviews
* Ensures only validated code is merged

---

## 👨‍💻 8. CODEOWNERS

👉 [View Documentation](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero/blob/c13c228b30b8e2d9438d1f69aabc73e40c5274af/Episode-04-git/CODEOWNERS.md)

* Automatically assigns reviewers
* Enforces ownership of code
* Ensures correct people approve changes

---

## 🤖 9. Dependabot

👉 [View Documentation](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero/blob/c13c228b30b8e2d9438d1f69aabc73e40c5274af/Episode-04-git/Dependabot.md)

* Automatically updates dependencies
* Fixes security vulnerabilities
* Creates pull requests for updates

---

## 🚀 Final Outcome

By combining all these components, we achieve:

* 🔒 Local security (pre-commit hooks)
* ⚙️ CI/CD security (GitHub Actions)
* 👥 Access control (RBAC, CODEOWNERS)
* 🛡️ Repository protection (Branch Protection)
* 🤖 Automated updates (Dependabot)

---


