# 🛡️ DevSecOps Zero to Hero

A complete hands-on DevSecOps course — from fundamentals to production-ready secure pipelines. Each episode is structured for 1-hour learning with real commands, real tools, and real configurations.

**GitHub:** [github.com/arumullayaswanth/DevSecOps-Zero-to-Hero](https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero)

---

## 📚 Course Content

| Episode | Topic | What You'll Learn |
|---------|-------|-------------------|
| 01 | Course Introduction | What we are going to learn in this entire playlist |
| 02 | DevSecOps Introduction | What is DevSecOps, Shift-Left, Pipeline Overview, Tools Overview |
| 03 | Secure CI/CD Pipeline | Jenkins Pipeline, SonarQube, Snyk, Trivy, OWASP ZAP, Falco |
| 04 | Git Security | Pre-Commit Hooks, Gitleaks, GitHub Actions, Branch Protection, CODEOWNERS, Dependabot |
| 05 | Container Security | Non-Root Containers, Multi-Stage Builds, Distroless, Trivy, OSV Scanner |
| 06 | Kubernetes Security | RBAC, Network Policies, Pod Security Standards, Secrets Management |
| 07 | IaC Security | Terraform Security, Checkov, Misconfiguration Detection |
| 08 | Runtime Security | Linux Capabilities, Seccomp Profiles, AppArmor, Falco |
| 09 | End-to-End Pipeline | Complete DevSecOps Pipeline integrating all tools |

---

## 📖 Episode 01 — Course Introduction

**📁 Folder:** `Episode-01,2-DevSecOps-Introduction/`

**Topics Covered:**
- What we are going to learn in this entire playlist (course roadmap)

**Key Takeaway:** Overview of the full course — what topics, tools, and episodes are coming.

---

## 📖 Episode 02 — DevSecOps Introduction

**📁 Folder:** `Episode-01,2-DevSecOps-Introduction/`

**Topics Covered:**
- What is DevSecOps?
- What is the full course about — episode-by-episode overview
- DevOps vs DevSecOps — how security fits into DevOps
- Shift-Left Security — why finding bugs early saves time and money
- Overview of tools we'll use throughout the course
- How the pipeline works end-to-end (Code → Scan → Build → Deploy → Monitor)
- Security at every stage — what tool does what
- SAST, SCA, DAST, Container Scanning — what each term means
- Real-world pipeline architecture
- Introduction to the Weather App project used in Episode 03

**Key Takeaway:** Understand what DevSecOps is, how it differs from DevOps, and the full pipeline picture before we start building.

---

## 🔐 Episode 03 — Secure CI/CD Pipeline

**📁 Folder:** `Episode-03-Secure-CICD-Pipeline/`

**Topics Covered:**
- End-to-end Jenkins pipeline for a React Weather App
- Pipeline flow: Code → GitHub → Jenkins → Security Scans → Docker → ECR → Kubernetes → DAST
- Tools integrated in the pipeline:

| Tool | Purpose |
|------|---------|
| SonarQube | SAST — static code analysis |
| Snyk | Dependency vulnerability scanning |
| Gitleaks | Secret detection in code |
| Trivy | Container image vulnerability scanning |
| Checkov | IaC (Kubernetes YAML) scanning |
| OWASP ZAP | DAST — dynamic testing of live app |
| Falco | Runtime security monitoring |

- Jenkins pipeline stages (14 stages from checkout to DAST)
- Docker image build and push to Amazon ECR
- Kubernetes deployment on EC2 with k3s

**Key Takeaway:** Every stage of CI/CD has a security check — no code reaches production without being scanned.

---

## 🔒 Episode 04 — Git Security

**📁 Folder:** `Episode-04-git/`

**Topics Covered:**
1. **.gitignore** — Prevent sensitive files from being tracked
2. **Pre-Commit Hook (Basic)** — Custom hook to block commits with secrets
3. **Pre-Commit Framework + Gitleaks** — Automated secret scanning before every commit
4. **Gitleaks Repository Scan** — Scan entire repo history for leaked secrets
5. **GitHub Actions** — Automate Gitleaks in CI/CD on push and PR
6. **RBAC (Role-Based Access Control)** — Control who can access/modify the repo
7. **Branch Protection** — Require PRs, reviews, and status checks before merge
8. **CODEOWNERS** — Auto-assign reviewers based on file ownership
9. **Dependabot** — Automatically update vulnerable dependencies

**Key Takeaway:** Security starts at the developer's machine — pre-commit hooks catch secrets before they ever reach GitHub.

---

## 🐳 Episode 05 — Container Security

**📁 Folder:** `Episode-05-Container-Security/`

**Topics Covered:**

### Section 1: Non-Root Containers (15 min)
- Why running as root is dangerous
- Creating non-root users in Dockerfiles
- `USER` directive, `--chown` flag
- Verifying with `whoami`, `id`, `docker inspect`
- Read-only filesystem with `--read-only`

### Section 2: Image Size Optimization (20 min)
- **Multi-Stage Builds** — Build in one image, run in another (900MB → 15MB)
- **Distroless Images** — No shell, no package manager, no OS tools
- **Attack Surface Reduction** — `.dockerignore`, pinned versions, minimal packages

### Section 3: Image Scanning (25 min)
- **CVEs** — What they are, severity levels (Critical/High/Medium/Low)
- **Trivy** — Scan images, filter by severity, fail CI/CD on critical CVEs
- **OSV Scanner** — Google's dependency vulnerability scanner
- **Trivy vs OSV Scanner** — When to use which
- GitHub Actions workflow for automated scanning

**Hands-On Images Built:**
```
myapp:insecure   — ❌ Root, full image, ~900MB
myapp:secure     — ✅ Non-root, multi-stage, slim, ~200MB
myapp:distroless — ✅ No shell, static binary, ~15MB
```

**Key Takeaway:** Smaller image = fewer vulnerabilities = smaller attack surface. Always run as non-root.
## 🎓 Free Course

- [Developing Secure Software (LFD121)](https://openssf.org/training/courses/) — Free course by OpenSSF (Open Source Security Foundation) covering secure software development practices including container security
---

## ☸️ Episode 06 — Kubernetes Security

**📁 Folder:** `Episode-06-Kubernetes-Security/`

**Topics Covered:**
- **RBAC (Role-Based Access Control)** — Roles, ClusterRoles, RoleBindings
- **Network Policies** — Control pod-to-pod communication
- **Pod Security Standards** — Restricted, Baseline, Privileged
- **Secrets Management** — Kubernetes secrets, external secret stores
- **Service Account Security** — Disable auto-mount, least privilege

**Key Takeaway:** Kubernetes is not secure by default — you must explicitly restrict access, network, and pod privileges.

---

## 🏗️ Episode 07 — Infrastructure as Code (IaC) Security

**📁 Folder:** `Episode-07-IaC-Security/`

**Topics Covered:**
- **Terraform Security** — Insecure vs Secure configurations
- **Checkov** — Scan Terraform/Kubernetes files for misconfigurations
- **Common IaC Mistakes:**
  - Open security groups (0.0.0.0/0)
  - Unencrypted S3 buckets
  - Public RDS instances
  - Missing logging/monitoring
- **Compliance as Code** — Enforce security policies automatically

**Key Takeaway:** Infrastructure misconfigurations are the #1 cause of cloud breaches — scan IaC before applying.

---

## 🛡️ Episode 08 — Runtime Security

**📁 Folder:** `Episode-08-Runtime-Security/`

**Topics Covered:**

### Section 1: Linux Capabilities (15 min)
- What capabilities are (breaking root into smaller privileges)
- Default Docker capabilities vs dangerous ones
- `--cap-drop=ALL --cap-add=<only-needed>` pattern
- Capabilities in Docker Compose and Kubernetes

### Section 2: Seccomp Profiles (20 min)
- System call filtering — block dangerous syscalls
- Docker's default seccomp profile (blocks ~44 syscalls)
- Custom seccomp profiles (deny by default, allow only needed)
- Seccomp in Kubernetes pods

### Section 3: AppArmor (15 min)
- Mandatory Access Control — restrict file/network access per process
- Docker's default AppArmor profile
- Custom AppArmor profiles for nginx
- Enforce vs Complain mode

### Section 4: Falco (10 min)
- Runtime threat detection using eBPF
- Detect: shell in container, sensitive file reads, crypto mining, reverse shells
- Custom Falco rules
- Helm deployment on Kubernetes

**Key Takeaway:** Even after deployment, containers need runtime protection — capabilities, seccomp, AppArmor, and Falco work together to detect and prevent attacks.

---

## 🚀 Episode 09 — End-to-End DevSecOps Pipeline

**📁 Folder:** `Episode-9-End-to-End-DevSecOps-Pipeline/`

**Topics Covered:**
- Complete production-ready pipeline integrating ALL previous episodes
- Full security automation from commit to production
- Pipeline: Code → Secret Scan → SAST → SCA → Build → Container Scan → IaC Scan → Deploy → DAST → Runtime Monitoring
- Incident response and alerting
- Continuous monitoring and compliance

**Key Takeaway:** DevSecOps is not one tool — it's the integration of security at every layer, automated end-to-end.

---

## 🗺️ DevSecOps Pipeline — Big Picture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          DevSecOps Pipeline Flow                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Developer        Pre-Commit         CI/CD Pipeline         Production          │
│  ─────────        ──────────         ──────────────         ──────────          │
│                                                                                 │
│  Write Code  →  Gitleaks Scan  →  SAST (SonarQube)    →  Runtime (Falco)       │
│                                   SCA (Snyk)                                    │
│                                   Container Scan (Trivy)                        │
│                                   IaC Scan (Checkov)                            │
│                                   DAST (OWASP ZAP)                              │
│                                                                                 │
│  Episode 01-02   Episode 04       Episode 03, 05, 07     Episode 08             │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tools Used in This Course

| Tool | Category | Episode |
|------|----------|---------|
| Gitleaks | Secret Detection | 04 |
| Pre-Commit Framework | Git Hooks | 04 |
| SonarQube | SAST (Static Analysis) | 03 |
| Snyk | SCA (Dependency Scan) | 03 |
| Trivy | Container/Image Scanning | 05 |
| OSV Scanner | Dependency Scanning | 05 |
| Checkov | IaC Scanning | 07 |
| OWASP ZAP | DAST (Dynamic Testing) | 03 |
| Falco | Runtime Security | 08 |
| Docker | Containerization | 05 |
| Kubernetes | Orchestration | 06 |
| Terraform | Infrastructure as Code | 07 |
| Jenkins | CI/CD | 03 |
| GitHub Actions | CI/CD | 04 |
| AppArmor | MAC (Mandatory Access Control) | 08 |
| Seccomp | System Call Filtering | 08 |

---

## 🚀 Getting Started

```bash
# Clone this repository
git clone https://github.com/arumullayaswanth/DevSecOps-Zero-to-Hero.git

# Navigate to the project
cd DevSecOps-Zero-to-Hero

# Start with Episode 01
cd Episode-01,2-DevSecOps-Introduction
```

---

## 👨‍💻 Author

**Yaswanth Reddy Arumulla**

- GitHub: [github.com/arumullayaswanth](https://github.com/arumullayaswanth)

---

## ⭐ If this helps you, give it a star!
