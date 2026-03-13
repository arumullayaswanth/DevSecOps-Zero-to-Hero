

# Episode 3 — DevSecOps Pipeline Deployment

## Project Repository

The project used in this episode is located here:

```
https://github.com/arumullayaswanth/weather-app-devsecops
```

This repository contains the actual application and pipeline configuration.

---

# Project Overview

This project demonstrates a **complete DevSecOps pipeline** for a React Weather Application.

The pipeline automatically performs:

```
Code → Security Scans → Build → Push → Deploy
```

---

# Tools Used

| Tool             | Purpose                       |
| ---------------- | ----------------------------- |
| GitHub           | Source code                   |
| Jenkins          | CI/CD pipeline                |
| SonarQube        | Static code security scan     |
| Snyk             | Dependency vulnerability scan |
| Gitleaks         | Secret detection              |
| Docker           | Containerization              |
| Trivy            | Container vulnerability scan  |
| Amazon ECR       | Container registry            |
| Kubernetes (k3s) | Deployment                    |
| Checkov          | Kubernetes security scan      |
| OWASP ZAP        | Dynamic security testing      |
| Falco            | Runtime security monitoring   |

---

# Project Repository Structure

Inside the project repository:

```
weather-app-devsecops
│
├ src
├ public
├ Jenkinsfile
├ Dockerfile
├ nginx.conf
├ sonar-project.properties
│
└ k8s
   ├ namespace.yaml
   ├ deployment.yaml
   └ service.yaml
```

Important files to understand:

| File                | Purpose               |
| ------------------- | --------------------- |
| Jenkinsfile         | DevSecOps pipeline    |
| Dockerfile          | Builds container      |
| k8s/deployment.yaml | Kubernetes deployment |
| k8s/service.yaml    | Kubernetes service    |

---

# Pipeline Flow

When code is pushed:

```
Developer
   ↓
GitHub
   ↓
Jenkins Pipeline
   ↓
Gitleaks (Secrets Scan)
   ↓
SonarQube (Code Scan)
   ↓
Snyk (Dependency Scan)
   ↓
Docker Build
   ↓
Trivy (Container Scan)
   ↓
Push Image to ECR
   ↓
Checkov (Kubernetes Scan)
   ↓
Deploy to Kubernetes
   ↓
OWASP ZAP Scan
```

---

# How to Deploy This Project

Follow the instructions in the project repository:

```
weather-app-devsecops
```

Steps include:

1️⃣ Create EC2 instance
2️⃣ Install Jenkins
3️⃣ Install Docker
4️⃣ Install Kubernetes (k3s)
5️⃣ Configure SonarQube
6️⃣ Configure Snyk
7️⃣ Configure Jenkins pipeline
8️⃣ Deploy the application

---

# Application URL

Once deployed:

```
http://EC2_PUBLIC_IP:30080
```

---

# Episode Summary

In this episode we learned how to:

```
Build a complete DevSecOps pipeline
Secure the application
Deploy to Kubernetes
Run automated security testing
```

---

so help you build a **professional DevSecOps-Zero-to-Hero GitHub structure with 10 episodes** that looks like a **full DevOps learning roadmap**.
