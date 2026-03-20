# 👥 CODEOWNERS (GitHub)

The `CODEOWNERS` file defines who is responsible for specific parts of the codebase and automatically requests reviews when changes are made.

---

## 🚀 Step 1: Create CODEOWNERS File

Create the file in one of these locations:

```bash
.github/CODEOWNERS
```

---

## 🧩 Step 2: Add Rules

### 📌 Example Configuration

```bash
# Global owner (all files)
*       @your-username

# Specific file
README.md   @your-username

# Folder ownership
/src/       @backend-team

# Multiple owners
*.js        @frontend-dev @team-lead
```

---

## ⚙️ How It Works

* When a pull request is created:

  * GitHub automatically assigns reviewers based on file changes
* Only assigned owners can approve (if required in branch protection)

---

## 🔒 Integration with Branch Protection

Enable:

* ✔️ Require pull request reviews before merging
* ✔️ Require review from Code Owners

👉 This ensures:

* ❌ No approval → No merge
* ✅ Approved by owner → Merge allowed

---

## 🧠 Why Use CODEOWNERS?

| Feature                | Benefit                       |
| ---------------------- | ----------------------------- |
| Auto review assignment | Saves time                    |
| Ownership clarity      | Clear responsibility          |
| Enforced approvals     | Better code quality           |
| Security               | Prevents unauthorized changes |

---

## 📊 Example Scenario

| File Changed  | Reviewer Assigned |
| ------------- | ----------------- |
| `/src/app.py` | `@backend-team`   |
| `README.md`   | `@your-username`  |
| `.js files`   | `@frontend-dev`   |

---

## 🚀 Best Practice

* Assign teams instead of individuals
* Combine with branch protection rules
* Keep rules simple and clear

---

## 💡 Summary

* `CODEOWNERS` = **Who reviews what**
* Works automatically with pull requests
* Enforced via branch protection

---

## 🔐 Final Thought

> CODEOWNERS ensures the right people review the right code — making your repository secure and maintainable.
