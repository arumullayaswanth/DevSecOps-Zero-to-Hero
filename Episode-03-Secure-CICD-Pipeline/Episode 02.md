# 🚀 Episode 02 — DevSecOps Architecture

In this episode we explore the **architecture of modern DevSecOps pipelines** and understand how security integrates into the CI/CD workflow.

---

## 🎯 Goal

Understand the **real architecture used in modern DevSecOps pipelines** and where security fits in the software delivery lifecycle.

---

## 🏗 DevSecOps Pipeline Flow

A typical DevSecOps pipeline looks like this:

Developer  
↓  
GitHub / GitLab  
↓  
CI Pipeline  
↓  
Security Scans  
↓  
Container Build  
↓  
Kubernetes Deployment  

### Explanation

**Developer**  
Developers write application code and push it to a Git repository.

**GitHub / GitLab**  
Source code management platforms that trigger CI/CD pipelines.

**CI Pipeline**  
Automation pipeline that builds, tests, and scans the application.

**Security Scans**  
Automated security tools scan the code, dependencies, and containers.

**Container Build**  
The application is packaged into a Docker container.

**Kubernetes Deployment**  
The containerized application is deployed into a Kubernetes cluster.

---

## 🔧 Tools Introduced

The following tools are commonly used in a DevSecOps architecture.

- GitHub / GitLab
- Jenkins / GitHub Actions
- SonarQube
- Snyk / Trivy
- Docker
- Kubernetes
- OWASP ZAP

---

## 🛡 Core Security Categories in DevSecOps

DevSecOps pipelines include multiple types of security testing.

| Category | Tool |
|--------|------|
| SAST | SonarQube |
| Dependency Scan | Snyk |
| Container Scan | Trivy |
| Secrets Scan | Gitleaks |
| DAST | OWASP ZAP |
| IaC Security | Checkov |
| Runtime Security | Falco |

---

## 🔍 What Each Category Does

**SAST (Static Application Security Testing)**  
Analyzes source code for vulnerabilities before the application runs.

**Dependency Scanning**  
Detects vulnerable open-source libraries used by the application.

**Container Scanning**  
Scans Docker images for known vulnerabilities.

**Secrets Scanning**  
Detects exposed credentials such as API keys or tokens.

**DAST (Dynamic Application Security Testing)**  
Tests a running application for real-world vulnerabilities.

**Infrastructure as Code Security**  
Checks Terraform or cloud configuration files for misconfigurations.

**Runtime Security**  
Monitors running containers for suspicious behavior.

---

## 🧪 Demo Idea

In this episode we will **scan a vulnerable application repository** using DevSecOps tools.

Steps:

1. Create a sample vulnerable application repository
2. Commit the code to GitHub
3. Run security scans using CI/CD pipeline
4. Detect vulnerabilities in:
   - Source code
   - Dependencies
   - Container image
5. Fix the vulnerabilities and rerun the pipeline

---

## 📂 Repository Structure
https://github.com/arumullayaswanth/weather-app-devsecops.git
