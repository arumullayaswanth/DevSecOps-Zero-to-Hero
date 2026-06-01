# Episode 05 - Container Security

## 🎯 Episode Structure (1 Hour)

| # | Topic | Duration | Focus |
|---|-------|----------|-------|
| 1 | Non-Root Containers | 15 min | Running containers as non-root users |
| 2 | Image Size Optimization | 20 min | Multi-Stage Builds, Distroless Images, Attack Surface Reduction |
| 3 | Image Scanning | 25 min | Vulnerability Scanning, CVEs, Trivy, OSV Scanner |

---

## 1️⃣ Non-Root Containers (15 min)

### Why Non-Root?

By default, containers run as **root (UID 0)**. This is a critical security risk because:
- If an attacker escapes the container, they have root on the host
- Root inside the container can modify system files, install packages, and escalate privileges
- Violates the **Principle of Least Privilege**

### The Problem — Insecure Dockerfile

```dockerfile
# ❌ BAD: Runs as root by default
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

### The Fix — Non-Root Dockerfile

```dockerfile
# ✅ GOOD: Runs as non-root user
FROM node:18-slim

# Create a non-root user and group
RUN groupadd -r appgroup && useradd -r -g appgroup -d /app -s /sbin/nologin appuser

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

EXPOSE 3000
CMD ["node", "server.js"]
```

### Key Commands

```bash
# Verify which user the container runs as
docker run --rm <image> whoami
docker run --rm <image> id

# Inspect the user directive
docker inspect <image> --format '{{.Config.User}}'
```

### Best Practices

- Always use `USER` directive in Dockerfiles
- Create a dedicated user/group for the application
- Use `--chown` flag when copying files
- Set proper file permissions before switching user
- Use `--read-only` flag at runtime for extra hardening

```bash
# Run with read-only filesystem
docker run --read-only --tmpfs /tmp <image>
```

---

## 2️⃣ Image Size Optimization (20 min)

### Why Image Size Matters for Security

| Concern | Impact |
|---------|--------|
| Larger attack surface | More packages = more potential vulnerabilities |
| Slower deployments | Larger images take longer to pull |
| More CVEs to patch | Unused tools still need security updates |
| Supply chain risk | More dependencies = more trust required |

---

### Multi-Stage Builds

Multi-stage builds let you use one image for building and a different (smaller) image for running.

#### Single-Stage (Bad)

```dockerfile
# ❌ BAD: Build tools remain in final image (~900MB)
FROM golang:1.21
WORKDIR /app
COPY . .
RUN go build -o myapp
CMD ["./myapp"]
```

#### Multi-Stage (Good)

```dockerfile
# ✅ GOOD: Only the binary goes into the final image (~15MB)

# Stage 1: Build
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o myapp .

# Stage 2: Run
FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/myapp .
USER nobody
CMD ["./myapp"]
```

#### Multi-Stage for Node.js

```dockerfile
# Stage 1: Install dependencies
FROM node:18 AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --production

# Stage 2: Production image
FROM node:18-slim
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

---

### Distroless Images

Distroless images from Google contain **only your application and its runtime dependencies**. No shell, no package manager, no OS utilities.

#### What's Removed in Distroless?

- ❌ Shell (`/bin/sh`, `/bin/bash`)
- ❌ Package managers (`apt`, `yum`)
- ❌ System utilities (`curl`, `wget`, `ls`)
- ❌ Unnecessary libraries

#### Example: Go with Distroless

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o myapp .

# Run stage — Distroless
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/myapp /
USER nonroot:nonroot
CMD ["/myapp"]
```

#### Example: Java with Distroless

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn package -DskipTests

FROM gcr.io/distroless/java17-debian12
COPY --from=builder /app/target/myapp.jar /app.jar
USER nonroot:nonroot
CMD ["app.jar"]
```

#### Example: Python with Distroless

```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/deps -r requirements.txt
COPY . .

FROM gcr.io/distroless/python3-debian12
WORKDIR /app
COPY --from=builder /app /app
ENV PYTHONPATH=/app/deps
USER nonroot:nonroot
CMD ["main.py"]
```

#### Available Distroless Images

| Image | Use Case |
|-------|----------|
| `gcr.io/distroless/static-debian12` | Statically compiled binaries (Go, Rust) |
| `gcr.io/distroless/base-debian12` | Dynamically linked binaries |
| `gcr.io/distroless/java17-debian12` | Java applications |
| `gcr.io/distroless/python3-debian12` | Python applications |
| `gcr.io/distroless/nodejs18-debian12` | Node.js applications |

---

### Attack Surface Reduction

#### Image Size Comparison

```
ubuntu:22.04        ~77MB    — Full OS, many packages
node:18             ~900MB   — Full Node + OS tools
node:18-slim        ~200MB   — Reduced OS packages
node:18-alpine      ~170MB   — Minimal Alpine Linux
distroless/nodejs18 ~130MB   — No shell, no OS tools
```

#### Practical Tips

1. **Use `.dockerignore`** to exclude unnecessary files:
```
.git
node_modules
*.md
.env
tests/
.github/
```

2. **Pin base image versions** (avoid `latest`):
```dockerfile
# ❌ BAD
FROM node:latest

# ✅ GOOD
FROM node:18.19.0-slim
```

3. **Minimize layers and clean up in the same layer**:
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

4. **Don't install unnecessary packages**:
```dockerfile
RUN apt-get install -y --no-install-recommends <only-what-you-need>
```

---

## 3️⃣ Image Scanning (25 min)

### Understanding Vulnerabilities & CVEs

**CVE** = Common Vulnerabilities and Exposures — a standardized identifier for known security flaws.

| Severity | CVSS Score | Action |
|----------|-----------|--------|
| Critical | 9.0 - 10.0 | Fix immediately |
| High | 7.0 - 8.9 | Fix within days |
| Medium | 4.0 - 6.9 | Fix within weeks |
| Low | 0.1 - 3.9 | Fix when possible |

### Where Vulnerabilities Hide in Container Images

- OS packages (apt/apk packages)
- Application dependencies (npm, pip, maven)
- Base image itself
- Embedded binaries and libraries

---

### Trivy — Container Vulnerability Scanner

[Trivy](https://github.com/aquasecurity/trivy) by Aqua Security is the most popular open-source scanner for containers.

#### Installation

```bash
# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# macOS
brew install trivy

# Docker (no install needed)
docker run aquasec/trivy image <your-image>
```

#### Basic Scanning

```bash
# Scan a container image
trivy image nginx:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL nginx:latest

# Scan and fail on critical vulnerabilities (for CI/CD)
trivy image --exit-code 1 --severity CRITICAL nginx:latest

# Scan a local Dockerfile
trivy config ./Dockerfile

# Scan filesystem (source code dependencies)
trivy fs --scanners vuln,secret .
```

#### Trivy Output Example

```
nginx:latest (debian 12.4)
Total: 142 (HIGH: 23, CRITICAL: 5)

┌──────────────────┬────────────────┬──────────┬────────────────────┬───────────────┬──────────────────────────────────────┐
│     Library      │ Vulnerability  │ Severity │ Installed Version  │ Fixed Version │                Title                 │
├──────────────────┼────────────────┼──────────┼────────────────────┼───────────────┼──────────────────────────────────────┤
│ libssl3          │ CVE-2024-XXXX  │ CRITICAL │ 3.0.11-1           │ 3.0.13-1      │ OpenSSL: Buffer overflow in...       │
│ curl             │ CVE-2024-YYYY  │ HIGH     │ 7.88.1-10          │ 7.88.1-11     │ curl: Use after free in...           │
└──────────────────┴────────────────┴──────────┴────────────────────┴───────────────┴──────────────────────────────────────┘
```

#### Trivy in CI/CD (GitHub Actions)

```yaml
name: Container Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'

      - name: Run Trivy and upload SARIF
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
```

---

### OSV Scanner — Google's Vulnerability Scanner

[OSV Scanner](https://github.com/google/osv-scanner) by Google scans dependencies against the OSV (Open Source Vulnerabilities) database.

#### Installation

```bash
# Go install
go install github.com/google/osv-scanner/cmd/osv-scanner@latest

# macOS
brew install osv-scanner

# Docker
docker run -v $(pwd):/src ghcr.io/google/osv-scanner -r /src
```

#### Basic Usage

```bash
# Scan current directory recursively
osv-scanner -r .

# Scan a specific lockfile
osv-scanner --lockfile=package-lock.json

# Scan a Docker image
osv-scanner --docker nginx:1.25

# Scan with SBOM
osv-scanner --sbom=sbom.json

# Output as JSON
osv-scanner -r --format json .
```

#### OSV Scanner in CI/CD (GitHub Actions)

```yaml
name: OSV Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  osv-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run OSV Scanner
        uses: google/osv-scanner-action/osv-scanner-action@v1
        with:
          scan-args: |-
            --recursive
            --format=sarif
            --output=osv-results.sarif
            .

      - name: Upload OSV scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'osv-results.sarif'
```

---

### Trivy vs OSV Scanner — Comparison

| Feature | Trivy | OSV Scanner |
|---------|-------|-------------|
| Container image scanning | ✅ | ✅ (via Docker) |
| OS package vulnerabilities | ✅ | ❌ |
| Application dependencies | ✅ | ✅ |
| Dockerfile misconfiguration | ✅ | ❌ |
| Secret detection | ✅ | ❌ |
| SBOM generation | ✅ | ✅ |
| Database | NVD + vendor advisories | OSV.dev (aggregated) |
| Best for | Full container security | Dependency-focused scanning |

---

## 🧪 Hands-On Lab

### Lab 1: Build a Secure Container

```bash
# 1. Build the insecure image
docker build -t myapp:insecure -f Dockerfile.insecure .

# 2. Build the secure image
docker build -t myapp:secure -f Dockerfile.secure .

# 3. Compare sizes
docker images | grep myapp

# 4. Verify non-root user
docker run --rm myapp:secure whoami
# Expected: appuser (NOT root)

# 5. Scan both images
trivy image myapp:insecure
trivy image myapp:secure
```

### Lab 2: Scan and Fix Vulnerabilities

```bash
# 1. Scan an image
trivy image --severity HIGH,CRITICAL nginx:1.24

# 2. Update to a patched version
trivy image --severity HIGH,CRITICAL nginx:1.25

# 3. Compare vulnerability counts

# 4. Scan your project dependencies
trivy fs --scanners vuln .
osv-scanner -r .
```

---

## 📋 Container Security Checklist

- [ ] Run containers as non-root user (`USER` directive)
- [ ] Use multi-stage builds to minimize image size
- [ ] Use distroless or minimal base images
- [ ] Pin base image versions (no `latest` tag)
- [ ] Scan images for vulnerabilities in CI/CD
- [ ] Set `--read-only` filesystem at runtime
- [ ] Use `.dockerignore` to exclude sensitive files
- [ ] Don't store secrets in images
- [ ] Regularly rebuild images to pick up security patches
- [ ] Fail builds on CRITICAL/HIGH vulnerabilities

---

## 📚 Resources

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OSV Scanner](https://google.github.io/osv-scanner/)
- [Google Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
