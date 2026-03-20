# 🔐 Branch Protection (GitHub)

Branch protection ensures that code cannot be merged unless all required checks (like Gitleaks scans) pass successfully.

---

## 🚀 Step 1: Go to Repository Settings

1. Open your GitHub repository
2. Navigate to:
   👉 **Settings → Branches**

---

## ⚙️ Step 2: Add Branch Protection Rule

Click:

👉 **"Add branch protection rule"**

---

## 🧩 Step 3: Configure Rule

### 📌 Branch name pattern

```id="6r9g0v"
main
```

(or use `*` for all branches)

---

### ✅ Enable the following:

* ✔️ Require a pull request before merging
* ✔️ Require status checks to pass before merging
* ✔️ Require branches to be up to date before merging

---

## 🔍 Step 4: Select Status Check

After running your workflow at least once:

* Select your GitHub Action:

  ```id="m2zvxf"
  gitleaks / secret-detection
  ```

---

## 🔒 What Happens Now?

* ❌ If Gitleaks detects a secret → Merge is blocked
* ✅ If no secrets → Merge is allowed

---

## 🧠 Why This Is Important

Even if someone:

* Skips local hooks
* Disables pre-commit

👉 Branch protection ensures **nothing insecure gets merged**

---

## 📊 Summary

| Feature              | Benefit                        |
| -------------------- | ------------------------------ |
| Enforces checks      | No bypass possible             |
| Protects main branch | Prevents bad commits           |
| Works with CI        | Integrates with GitHub Actions |
| Security level       | 🔥 High                        |

---

## 🚀 Final Thought

> Pre-commit protects developers locally,
> GitHub Actions scans in CI,
> Branch protection enforces security at merge level.
