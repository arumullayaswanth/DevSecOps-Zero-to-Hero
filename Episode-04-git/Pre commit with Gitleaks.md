
# Pre-commit Framework with Gitleaks
#### step-1
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
  #### step-2
- Create config file
  ```bash
  vim .pre-commit-config.yaml
  ```
- Add this configuration
  ```bash
  repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks
        args: ["--no-git"]
  ```
- Install the hook
  ```bash
  pre-commit run --all-files
  ```
  or
  ```bash
  pre-commit install
  ```
  
#### 🔒 What happens now?

* On every commit:

  * Gitleaks scans your code
  * If secrets are found → ❌ commit blocked
  * If clean → ✅ commit allowed

---

# 🧠 Why this is better than your script

| Feature             | Your Script | Gitleaks + pre-commit |
| ------------------- | ----------- | --------------------- |
| Detect real secrets | ❌           | ✅                     |
| Detect API keys     | ❌           | ✅                     |
| Detect tokens       | ❌           | ✅                     |
| Accuracy            | Low         | High                  |
| Automation          | Manual      | Automatic             |



#### step-3 Test
```bash
vim app.py
```
```bash
code
```
- Stage the file
git add app.py
- Try to commit
git commit -m "test secret detection"

> Now let’s stop secrets before they even enter Git.

