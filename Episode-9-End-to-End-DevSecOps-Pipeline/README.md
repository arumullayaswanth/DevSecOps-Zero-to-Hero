# Episode 09 — End-to-End DevSecOps Pipeline (Production Level)

## What is this?

This is the final episode. Everything we learned from Episode 01 to 08 — we're putting it all into ONE production-level project with GitHub Actions.

No Jenkins this time. Pure GitHub Actions. The way most companies do it in 2024-2025.

One repository. One pipeline. Every security check automated. Deploy to Kubernetes. Falco monitoring after deployment.

---

## The Project

A simple **Python Flask API** (weather/notes app — you decide). But the real focus is the pipeline, not the app. The app is intentionally simple so the security pipeline is the star.

---

## What the Pipeline Does (Everything from Ep 01-08)

```
Developer pushes code
        │
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS PIPELINE                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  STAGE 1: SECRET SCANNING (Episode 04)                               │
│  → Gitleaks scans for API keys, passwords, tokens in code            │
│                                                                       │
│  STAGE 2: SAST — Static Code Analysis (Episode 03)                   │
│  → SonarQube scans code quality + security vulnerabilities           │
│                                                                       │
│  STAGE 3: DEPENDENCY SCAN — SCA (Episode 03)                         │
│  → Snyk / Trivy scans dependencies (requirements.txt/package.json)   │
│                                                                       │
│  STAGE 4: BUILD DOCKER IMAGE (Episode 05)                            │
│  → Multi-stage build, non-root user, distroless/slim base image      │
│                                                                       │
│  STAGE 5: CONTAINER IMAGE SCAN (Episode 05)                          │
│  → Trivy scans the built image for CVEs                              │
│  → Fail pipeline if CRITICAL or HIGH found                           │
│                                                                       │
│  STAGE 6: IaC SCAN (Episode 07)                                      │
│  → Checkov scans Kubernetes YAML and Dockerfile                      │
│                                                                       │
│  STAGE 7: PUSH IMAGE TO REGISTRY                                     │
│  → Push to Amazon ECR (authenticate via OIDC — no access keys)       │
│                                                                       │
│  STAGE 8: DEPLOY TO KUBERNETES (Episode 06)                          │
│  → kubectl apply deployment with:                                     │
│    - Non-root user                                                    │
│    - Read-only filesystem                                             │
│    - Drop ALL capabilities                                            │
│    - Resource limits                                                  │
│    - Network policies                                                 │
│  → Authenticate to EKS via OIDC (no kubeconfig secrets)              │
│                                                                       │
│  STAGE 9: DAST — Dynamic Scan (Episode 03)                           │
│  → OWASP ZAP scans the live deployed application                     │
│                                                                       │
│  STAGE 10: RUNTIME MONITORING (Episode 08)                           │
│  → Falco already running on cluster, detects any runtime threats     │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure (What You Will Create)

```
Episode-9-End-to-End-DevSecOps-Pipeline/
├── README.md                          ← This file (reference guide)
├── app/
│   ├── app.py                         ← Flask application
│   ├── requirements.txt               ← Python dependencies
│   ├── tests/
│   │   └── test_app.py               ← Unit tests
│   └── Dockerfile                     ← Multi-stage, non-root, slim
├── k8s/
│   ├── namespace.yaml                 ← Namespace with PSS restricted
│   ├── deployment.yaml                ← Hardened deployment
│   ├── service.yaml                   ← ClusterIP service
│   ├── ingress.yaml                   ← Ingress (optional)
│   └── networkpolicy.yaml             ← Deny-all + allow specific
├── .github/
│   └── workflows/
│       └── devsecops-pipeline.yml     ← The complete pipeline
├── sonar-project.properties           ← SonarQube config
├── .gitleaks.toml                     ← Gitleaks config
└── .trivyignore                       ← Ignore false positives
```

---

## The Pipeline — 10 Stages (GitHub Actions)

### Stage 1: Secret Scanning (Episode 04)

What it does: Scans your entire codebase for accidentally committed secrets — API keys, passwords, tokens, private keys.

```yaml
- name: Secret Scan - Gitleaks
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

If Gitleaks finds a secret → pipeline FAILS. Fix it before moving forward.

---

### Stage 2: SAST — Static Application Security Testing (Episode 03)

What it does: Scans your source code for security bugs, code smells, and vulnerabilities WITHOUT running the application.

```yaml
- name: SonarQube Scan
  uses: SonarSource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

Catches things like: SQL injection patterns, hardcoded credentials, insecure functions, XSS vulnerabilities.

---

### Stage 3: Dependency Scan — SCA (Episode 03)

What it does: Checks all your dependencies (requirements.txt, package.json) against known vulnerability databases.

```yaml
- name: Dependency Scan - Trivy FS
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'table'
    exit-code: '1'
    severity: 'CRITICAL,HIGH'
```

Why: Your app might be secure, but if you import a library with a known CVE → you're vulnerable.

---

### Stage 4: Build Docker Image (Episode 05)

What it does: Builds a production-ready Docker image using:
- Multi-stage build (small image)
- Non-root user (security)
- Slim/distroless base (minimal attack surface)

```yaml
- name: Build Docker Image
  run: |
    docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
    docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
```

The Dockerfile follows everything from Episode 05:
- Stage 1: Install dependencies
- Stage 2: Copy only what's needed, run as non-root

---

### Stage 5: Container Image Scan (Episode 05)

What it does: Scans the BUILT Docker image for OS-level and library-level vulnerabilities.

```yaml
- name: Container Scan - Trivy Image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
    exit-code: '1'
    severity: 'CRITICAL,HIGH'
```

This catches: vulnerable OS packages in the base image, outdated libraries, known CVEs.

---

### Stage 6: IaC Security Scan (Episode 07)

What it does: Scans your Kubernetes YAML files and Dockerfile for security misconfigurations.

```yaml
- name: IaC Scan - Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    directory: k8s/
    framework: kubernetes
    output_format: sarif
    soft_fail: false
```

Catches things like: containers running as root, no resource limits set, privileged containers, no network policies.

---

### Stage 7: Push to Amazon ECR (Episode 07 — OIDC)

What it does: Pushes the scanned Docker image to Amazon ECR. Authenticates using OIDC — NO access keys stored anywhere.

```yaml
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ vars.AWS_ROLE_ARN }}
    aws-region: ${{ vars.AWS_REGION }}

- name: Login to Amazon ECR
  uses: aws-actions/amazon-ecr-login@v2

- name: Push Image to ECR
  run: |
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

This is the OIDC method from Episode 07. GitHub proves its identity to AWS, gets temporary credentials (1 hour), pushes the image. No long-lived keys.

---

### Stage 8: Deploy to Kubernetes (Episode 06)

What it does: Deploys the application to your EKS cluster with all security controls from Episode 06:
- Pod Security Standards (restricted namespace)
- Non-root user
- Read-only filesystem
- Drop ALL capabilities
- Resource limits
- Network policies (deny-all + allow specific)

```yaml
- name: Update kubeconfig
  run: |
    aws eks update-kubeconfig --name ${{ vars.EKS_CLUSTER_NAME }} --region ${{ vars.AWS_REGION }}

- name: Deploy to Kubernetes
  run: |
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/networkpolicy.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl rollout status deployment/app -n production --timeout=120s
```

---

### Stage 9: DAST — Dynamic Application Security Testing (Episode 03)

What it does: After the app is deployed and running, OWASP ZAP hits the live application from outside and looks for vulnerabilities.

```yaml
- name: DAST - OWASP ZAP Scan
  uses: zaproxy/action-full-scan@v0.10.0
  with:
    target: 'http://${{ env.APP_URL }}'
    rules_file_name: '.zap/rules.tsv'
    cmd_options: '-a'
```

Catches things like: missing security headers, XSS, CSRF, open redirects, information disclosure.

---

### Stage 10: Runtime Monitoring (Episode 08)

This isn't a pipeline stage — Falco is already running on your cluster (from Episode 08). It continuously monitors all deployed containers.

If someone:
- Gets shell access → Falco alerts
- Downloads malware → Falco alerts
- Reads /etc/shadow → Falco alerts
- Runs package manager → Falco alerts

You already set this up in Episode 08. It works 24/7 after deployment.

---

## GitHub Variables You Need (No Secrets Hardcoded)

| Variable | Where | Example |
|----------|-------|---------|
| `AWS_ROLE_ARN` | GitHub Vars | `arn:aws:iam::123456:role/GitHubActions-Role` |
| `AWS_REGION` | GitHub Vars | `ap-south-1` |
| `ECR_REPOSITORY` | GitHub Vars | `devsecops-app` |
| `EKS_CLUSTER_NAME` | GitHub Vars | `production-cluster` |
| `SONAR_TOKEN` | GitHub Secrets | `squ_xxxxx` |
| `SONAR_HOST_URL` | GitHub Secrets | `https://sonarcloud.io` |

No AWS Access Keys. No kubeconfig file. Everything via OIDC.

---

## The Dockerfile (Production Level)

```dockerfile
# Stage 1: Build
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/deps -r requirements.txt
COPY app.py .

# Stage 2: Production
FROM python:3.11-slim
RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin appuser
WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY --from=builder /app/app.py .
ENV PYTHONPATH=/app/deps
USER appuser
EXPOSE 8080
CMD ["python", "app.py"]
```

Why this matters:
- Multi-stage → small image, no build tools in production
- Non-root → attacker can't write to system files
- Slim base → minimal packages, fewer CVEs
- No shell needed in production (could use distroless too)

---

## The Kubernetes Deployment (Production Level)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: devsecops-app
  template:
    metadata:
      labels:
        app: devsecops-app
    spec:
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: <ECR_IMAGE>:latest
          ports:
            - containerPort: 8080
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          resources:
            limits:
              memory: "256Mi"
              cpu: "500m"
            requests:
              memory: "128Mi"
              cpu: "100m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir:
            medium: Memory
            sizeLimit: 64Mi
```

This uses everything from Episodes 05, 06, 08:
- Non-root (Ep 05)
- Read-only filesystem (Ep 05)
- Drop ALL capabilities (Ep 06)
- Resource limits (Ep 06)
- Seccomp RuntimeDefault (Ep 08)
- No service account token (Ep 06)

---

## Network Policy (Zero Trust)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: devsecops-app
  policyTypes:
    - Ingress
  ingress:
    - ports:
        - protocol: TCP
          port: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: devsecops-app
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
```

From Episode 06: Deny everything, then allow only what's needed.

---

## Namespace with Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

From Episode 06: Any insecure pod will be REJECTED by Kubernetes itself.

---

## How Everything Connects (Episode Map)

```
┌──────────────────────────────────────────────────────────────┐
│              COMPLETE DEVSECOPS PIPELINE                       │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  CODE PHASE (Before commit)                                    │
│  ├── Gitleaks pre-commit hook ............ Episode 04         │
│  └── .gitignore ......................... Episode 04         │
│                                                                │
│  BUILD PHASE (CI - on every push/PR)                           │
│  ├── Stage 1: Gitleaks .................. Episode 04         │
│  ├── Stage 2: SonarQube SAST ............ Episode 03         │
│  ├── Stage 3: Trivy/Snyk dependency ..... Episode 03         │
│  ├── Stage 4: Docker build .............. Episode 05         │
│  ├── Stage 5: Trivy image scan .......... Episode 05         │
│  └── Stage 6: Checkov IaC scan .......... Episode 07         │
│                                                                │
│  DEPLOY PHASE (CD - on merge to main)                          │
│  ├── Stage 7: Push to ECR (OIDC) ........ Episode 07         │
│  ├── Stage 8: Deploy to K8s ............. Episode 06         │
│  └── Stage 9: OWASP ZAP DAST ........... Episode 03         │
│                                                                │
│  RUNTIME PHASE (24/7 after deployment)                         │
│  └── Stage 10: Falco monitoring ......... Episode 08         │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## AWS Resources You Need

| Resource | Purpose | Cost |
|----------|---------|------|
| EKS Cluster | Run your app + Falco | ~$0.10/hr for cluster + nodes |
| ECR Repository | Store Docker images | Free tier for 500MB |
| IAM OIDC Provider | GitHub → AWS auth (no keys) | Free |
| S3 Bucket | Terraform state (if using Terraform for infra) | Cents |

To save cost: Use a `t3.medium` node group (2 nodes). Destroy after demo.

---

## Step-by-Step: How to Build This Project

### Step 1: Create the Flask app

Build a simple Python Flask API with:
- `GET /` → home page
- `GET /health` → health check
- `GET /api/data` → returns some JSON

### Step 2: Write Dockerfile (Episode 05 style)

Multi-stage, non-root, slim base.

### Step 3: Write Kubernetes YAMLs (Episode 06 style)

Namespace with PSS, hardened deployment, service, network policies.

### Step 4: Set up OIDC in AWS (Episode 07 style)

Create the GitHub OIDC provider + IAM role in your AWS account.

### Step 5: Create ECR repository

```bash
aws ecr create-repository --repository-name devsecops-app --region ap-south-1
```

### Step 6: Write GitHub Actions workflow

10 stages. Runs on push and PR. Uses OIDC for AWS auth.

### Step 7: Set up GitHub Variables

Add `AWS_ROLE_ARN`, `AWS_REGION`, `ECR_REPOSITORY`, `EKS_CLUSTER_NAME`, `SONAR_TOKEN` in repo settings.

### Step 8: Install Falco on cluster (Episode 08)

```bash
cd ../Episode-08-Runtime-Security/01-falco-production/
bash install.sh
```

### Step 9: Push code and watch the pipeline run

```bash
git add .
git commit -m "feat: complete devsecops pipeline"
git push origin main
```

Go to Actions tab → watch all 10 stages pass → app deployed → Falco watching.

---

## This Is What Companies Do

This isn't a tutorial project. This is exactly how companies like GitLab, Shopify, and Stripe ship code:

1. Developer writes code
2. Pushes to branch → PR created
3. Pipeline runs all security scans automatically
4. If any scan fails → PR blocked
5. Team reviews the PR + scan results
6. PR merged → deploy to production automatically
7. Falco watches production 24/7

No manual security reviews. No "we'll scan it later." Everything automated. Every push. Every time.

---

## What You'll Show in Your Video

```
1. Show the app running locally (30 seconds)
2. Push code to GitHub
3. Show GitHub Actions running all 10 stages
4. Show Gitleaks catching a test secret (then fix it)
5. Show Trivy catching a CVE in the image
6. Show Checkov catching a K8s misconfiguration
7. Show successful deployment to EKS
8. Show the app running in production
9. Show Falco detecting an attack on the running app
10. "This is DevSecOps. End to end. In production."
```

---

## Prerequisites

```
✅ AWS Account
✅ GitHub Account
✅ EKS Cluster running (or create with Terraform from Ep 07)
✅ Falco installed on cluster (from Ep 08)
✅ SonarCloud account (free for open source)
✅ Basic Python/Flask knowledge
```

---

## Resources

- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Trivy GitHub Action](https://github.com/aquasecurity/trivy-action)
- [Checkov GitHub Action](https://github.com/bridgecrewio/checkov-action)
- [OWASP ZAP GitHub Action](https://github.com/zaproxy/action-full-scan)
- [SonarCloud](https://sonarcloud.io/)
- [Amazon ECR](https://docs.aws.amazon.com/ecr/)
