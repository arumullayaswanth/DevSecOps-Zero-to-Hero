# Falco — Runtime Threat Detection (Production Setup)

## What is Falco?

Falco is a security tool that monitors your running containers in real-time.

Let me put it simply — you know how we scan container images before deploying them, right? We use Trivy, Snyk, etc. But what happens after the container is already running in production? What if an attacker gets inside your container right now?

That's where Falco comes in. It watches every single thing happening inside your containers — every file opened, every process started, every network connection made. The moment something suspicious happens, Falco raises an alert.

Falco was created by Sysdig, and now it's a CNCF Graduated project. That means it's at the same maturity level as Kubernetes itself. Companies like Shopify, GitLab, Skyscanner, and many banks use it in production.

---

## Why do we need Falco?

Let me give you a real scenario.

You built your Docker image. You scanned it with Trivy — zero critical vulnerabilities. You deployed it to Kubernetes. Everything looks clean.

Two days later, a new zero-day CVE drops. Your running container is now vulnerable. An attacker exploits it, gets shell access, downloads a crypto miner, and starts mining Bitcoin using YOUR servers. Your cloud bill shoots up. You don't even know it's happening because your build-time scans already passed.

This is the gap Falco fills.

Build-time scanning = one-time check at deploy time.
Falco = continuous monitoring AFTER deployment.

Without Falco, you're blind to what's happening inside your running containers.

---

## What can Falco detect?

Here's what Falco catches out of the box:

- Someone gets a shell inside your container (attacker running `bash` or `sh`)
- Someone reads sensitive files like `/etc/shadow` or Kubernetes service account tokens
- Someone uses `curl` or `wget` to download files (malware, crypto miners)
- Someone installs packages at runtime (`apt install`, `apk add`) — containers should be immutable
- Someone launches a privileged container (can escape to the host)
- Crypto mining processes running inside containers
- Reverse shell connections going outbound to attacker's server
- Writes to system binary directories (`/usr/bin`, `/sbin`) — malware installation

---

## How does Falco work?

Every container runs on top of the Linux kernel. Every time a container opens a file, starts a process, or connects to a network — it makes a system call to the kernel.

Falco uses eBPF to tap into these system calls. It doesn't need a kernel module, doesn't slow down your containers, and works on any managed Kubernetes service (EKS, GKE, AKS).

Falco has a rules engine. You write rules like "if a shell is spawned inside a container, alert me." When the rule matches, Falco generates an alert with full context — which container, which pod, which image, which user, which command.

Then Falco Sidekick takes that alert and sends it wherever you want — Slack, PagerDuty, Teams, Kafka, Elasticsearch, your SIEM.

---

## Who uses Falco?

- Shopify
- GitLab
- Skyscanner
- Multiple banks and financial institutions
- Healthcare companies (for HIPAA compliance)
- Government organizations
- Any company running Kubernetes in production that takes security seriously

---

## When should you use Falco?

Use it when:
- You're running containers in production
- You want to know the moment an attacker gets inside your cluster
- You need compliance (SOC2, PCI-DSS, HIPAA require runtime monitoring)
- You want to detect crypto miners before your cloud bill explodes
- You're building a complete DevSecOps pipeline and need the runtime layer

---

## What's inside this folder

| File | What it does |
|------|--------------|
| `install.sh` | Installs Falco on your K8s cluster using Helm |
| `uninstall.sh` | Removes Falco completely |
| `values-production.yaml` | Falco configuration with 9 custom detection rules |
| `attack-simulation.sh` | Simulates 5 real attacks and shows Falco catching them |

---

## What Falco detects (9 rules configured)

| # | Attack | What triggers it | Severity |
|---|--------|-----------------|----------|
| 1 | Shell access | Someone runs bash/sh/zsh inside a container | WARNING |
| 2 | Sensitive file read | Someone reads /etc/shadow, AWS creds, SSH keys | CRITICAL |
| 3 | Crypto mining | Processes like xmrig, stratum connections | CRITICAL |
| 4 | Package install | apt/yum/apk/pip/npm runs inside a running container | ERROR |
| 5 | Binary modification | Writes to /usr/bin or /sbin (malware drop) | CRITICAL |
| 6 | Reverse shell | /dev/tcp connections, netcat -e, python socket | CRITICAL |
| 7 | SA token read | Process reads K8s service account token | WARNING |
| 8 | Curl/Wget download | curl or wget executed in container | WARNING |
| 9 | Privileged container | A container starts with privileged: true | CRITICAL |

---

## Prerequisites

Before you start, make sure you have:

```
✅ A running Kubernetes cluster (minikube, kind, EKS, GKE — any works)
✅ kubectl configured and connected to your cluster
✅ Helm 3 installed
✅ Demo app deployed (from 00-vulnerable-app/) — optional but recommended
```

Check everything is ready:

```bash
kubectl cluster-info
helm version
```

---

## Step-by-Step Deployment

### Step 1: Clone the repo and go to this folder

```bash
git clone https://github.com/<your-username>/DevSecOps-Zero-to-Hero.git
cd DevSecOps-Zero-to-Hero/Episode-08-Runtime-Security/
```

### Step 2: Deploy the demo app first (recommended)

Deploy a real app so you can attack it later with Falco watching:

```bash
cd 00-vulnerable-app/
bash deploy.sh
```

Verify it's running:
```bash
kubectl get pods -l app=webapp
```

### Step 3: Install Falco

```bash
cd ../01-falco-production/
bash install.sh
```

This does 4 things:
1. Adds the Falco Helm chart repository
2. Creates a `falco` namespace
3. Installs Falco with our custom rules (from `values-production.yaml`)
4. Verifies everything is running

### Step 4: Verify Falco is running

```bash
# Check pods (you should see 1 Falco pod per node)
kubectl get pods -n falco

# Check DaemonSet
kubectl get daemonset -n falco

# Check logs — look for "Falco initialized" message
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=10
```

You should see output like:
```
NAME          READY   STATUS    RESTARTS   AGE
falco-xxxxx   2/2     Running   0          30s
```

### Step 5: Open Falco logs in a separate terminal

Keep this running in a second terminal — you'll see alerts appear here in real-time:

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco -f
```

### Step 6: Run the attack simulation

In your first terminal:

```bash
bash attack-simulation.sh
```

This runs 5 attacks one by one:

| # | What it does | What Falco shows |
|---|---|---|
| 1 | Runs `sh` inside a container | SHELL ACCESS DETECTED |
| 2 | Runs `apk add nmap` | PACKAGE MANAGER EXECUTED |
| 3 | Runs `wget` to download a file | DOWNLOAD TOOL USED IN CONTAINER |
| 4 | Reads `/etc/shadow` and SA token | CREDENTIAL ACCESS ATTEMPT |
| 5 | Launches a privileged container | PRIVILEGED CONTAINER LAUNCHED |

Watch your second terminal — Falco alerts pop up instantly after each attack.

### Step 7: Open the Falco Sidekick Web UI (optional)

Sidekick UI gives you a dashboard view of all alerts:

```bash
kubectl port-forward -n falco svc/falco-falcosidekick-ui 2802:2802
```

Open browser: http://localhost:2802

**Login credentials:**
- User: `admin`
- Password: `admin`

---

## How to add your own custom rules

Edit `values-production.yaml`, add your rule under `customRules`:

```yaml
customRules:
  custom-rules.yaml: |-
    - rule: My Custom Rule
      desc: What this detects
      condition: >
        spawned_process and
        container and
        proc.name = "suspicious-thing"
      output: >
        MY ALERT (container=%container.name pod=%k8s.pod.name)
      priority: CRITICAL
      tags: [custom]
```

Then upgrade Falco:

```bash
helm upgrade falco falcosecurity/falco -n falco --values values-production.yaml
```

---

## Cleanup

Remove everything when you're done:

```bash
# Delete test pods
kubectl delete pod victim-pod 2>/dev/null
kubectl delete pod privileged-pod 2>/dev/null

# Uninstall Falco
bash uninstall.sh
```

Or manually:

```bash
helm uninstall falco -n falco
kubectl delete namespace falco
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Falco pod is CrashLoopBackOff | Check logs: `kubectl logs -n falco -l app.kubernetes.io/name=falco`. Usually kernel headers missing. |
| No alerts showing | Make sure you're watching the right pod: `kubectl logs -n falco -l app.kubernetes.io/name=falco -f` |
| Helm install fails | Check Helm version (`helm version`). Needs Helm 3. |
| attack-simulation.sh fails | Make sure victim-pod is running: `kubectl get pod victim-pod` |
| Sidekick UI not loading | Run port-forward again: `kubectl port-forward -n falco svc/falco-falcosidekick-ui 2802:2802` |

---

## How this works in real companies

```
Your Cluster
    │
    ▼
Falco (runs on every node, watches all containers)
    │
    ▼
Falco Sidekick (receives alerts, routes them)
    │
    ├── Slack (#security-alerts)
    ├── PagerDuty (pages on-call engineer for CRITICAL)
    ├── Kafka / Elasticsearch (long-term storage)
    └── SIEM (Splunk, Datadog, ELK)
```

To enable Slack alerts, uncomment and fill in the Slack webhook in `values-production.yaml`:

```yaml
falcosidekick:
  config:
    slack:
      webhookurl: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
      channel: "#security-alerts"
      minimumpriority: "warning"
```

---

## What's next

After deploying Falco, check out:
- **Episode 05** — Container hardening (non-root, distroless images)
- **Episode 06** — Pod Security Standards, Network Policies, RBAC
- **Episode 09** — End-to-End DevSecOps Pipeline (everything together)
