# Episode 06 - Kubernetes Security

## 🎯 Episode Structure (1 Hour)

| # | Topic | Duration | Focus |
|---|-------|----------|-------|
| 1 | RBAC (Role-Based Access Control) | 20 min | Roles, ClusterRoles, Bindings |
| 2 | Network Policies | 15 min | Pod-to-pod traffic control |
| 3 | Pod Security Standards | 15 min | Restricted, Baseline, Privileged |
| 4 | Secrets Management | 10 min | Kubernetes secrets, best practices |

---

## 📁 Files in This Folder

| File | Purpose |
|------|---------|
| `rbac/01-namespace.yaml` | Create a dedicated namespace |
| `rbac/02-serviceaccount.yaml` | Service account for the app |
| `rbac/03-role.yaml` | Role with limited permissions |
| `rbac/04-rolebinding.yaml` | Bind role to service account |
| `rbac/05-clusterrole.yaml` | Cluster-wide read-only role |
| `rbac/06-clusterrolebinding.yaml` | Bind cluster role to user |
| `rbac/07-pod-with-sa.yaml` | Pod using the service account |
| `network-policy/01-deny-all.yaml` | Deny all traffic by default |
| `network-policy/02-allow-frontend-to-backend.yaml` | Allow ingress: frontend → backend |
| `network-policy/03-allow-ingress-only.yaml` | Allow only ingress traffic |
| `network-policy/04-allow-egress-dns.yaml` | Allow DNS egress (required for service discovery) |
| `network-policy/05-namespace-isolation.yaml` | Isolate namespaces from each other |
| `network-policy/06-allow-frontend-egress-to-backend.yaml` | Allow egress: frontend → backend |
| `network-policy/test-pods.yaml` | Test pods + services for verifying policies |
| `pod-security/01-restricted-pod.yaml` | Pod following restricted standards |
| `pod-security/02-baseline-pod.yaml` | Pod following baseline standards |
| `pod-security/03-privileged-pod.yaml` | ❌ Privileged pod (bad example) |
| `pod-security/04-namespace-enforcement.yaml` | Enforce PSS on namespace |
| `secrets/01-secret-opaque.yaml` | Basic Kubernetes secret |
| `secrets/02-secret-docker-registry.yaml` | Docker registry secret |
| `secrets/03-pod-with-secret.yaml` | Pod consuming secrets |
| `secrets/04-secret-as-env.yaml` | Secret as environment variable |

---

## 1️⃣ RBAC — Role-Based Access Control (20 min)

### What is RBAC?

RBAC controls **who can do what** in your Kubernetes cluster. By default, Kubernetes allows everything — you must explicitly restrict access.

### RBAC Components

```
┌─────────────────────────────────────────────────────────┐
│                    RBAC Model                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  WHO              WHAT              WHERE               │
│  ────              ────              ─────              │
│  User         →   Role          →   Namespace           │
│  Group        →   ClusterRole   →   Entire Cluster      │
│  ServiceAccount   (permissions)     (scope)             │
│                                                         │
│  Connected by: RoleBinding / ClusterRoleBinding         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Key Concepts

| Resource | Scope | Purpose |
|----------|-------|---------|
| Role | Namespace | Permissions within a single namespace |
| ClusterRole | Cluster-wide | Permissions across all namespaces |
| RoleBinding | Namespace | Connects Role to User/SA in a namespace |
| ClusterRoleBinding | Cluster-wide | Connects ClusterRole to User/SA globally |
| ServiceAccount | Namespace | Identity for pods/applications |

### Hands-On Commands

```bash
# Create the namespace for our demo
kubectl apply -f rbac/01-namespace.yaml

# Create service account
kubectl apply -f rbac/02-serviceaccount.yaml

# Create role with limited permissions
kubectl apply -f rbac/03-role.yaml

# Bind role to service account
kubectl apply -f rbac/04-rolebinding.yaml

# Create cluster-wide read-only role
kubectl apply -f rbac/05-clusterrole.yaml

# Bind cluster role
kubectl apply -f rbac/06-clusterrolebinding.yaml

# Deploy pod using the service account
kubectl apply -f rbac/07-pod-with-sa.yaml

# Verify: Check what the service account can do
kubectl auth can-i get pods --as=system:serviceaccount:devsecops-demo:app-service-account -n devsecops-demo
# Expected: yes

kubectl auth can-i delete pods --as=system:serviceaccount:devsecops-demo:app-service-account -n devsecops-demo
# Expected: no

kubectl auth can-i create deployments --as=system:serviceaccount:devsecops-demo:app-service-account -n devsecops-demo
# Expected: no

# List all roles in namespace
kubectl get roles -n devsecops-demo

# List all role bindings
kubectl get rolebindings -n devsecops-demo

# Describe a role to see its permissions
kubectl describe role app-role -n devsecops-demo
```

---

## 2️⃣ Network Policies (15 min)

### What are Network Policies?

By default, **all pods can talk to all other pods** in Kubernetes. Network Policies restrict which pods can communicate with each other.

### Default Behavior (No Network Policy)

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Frontend │ ──► │ Backend  │ ──► │ Database │
└──────────┘     └──────────┘     └──────────┘
      │                                  ▲
      └──────────────────────────────────┘
      ❌ Frontend can directly access Database (BAD!)
```

### With Network Policy (Secure)

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Frontend │ ──► │ Backend  │ ──► │ Database │
└──────────┘     └──────────┘     └──────────┘
      │                                  ▲
      └──────────── ✗ BLOCKED ───────────┘
      ✅ Frontend can ONLY talk to Backend
```

### Important: Network Plugin Required

Network Policies only work if your cluster has a CNI plugin that supports them:
- ✅ Calico
- ✅ Cilium
- ✅ Weave Net
- ❌ Flannel (does NOT support network policies)

### Hands-On Commands

```bash
# Step 1: Create namespace first (required for all other resources)
kubectl apply -f rbac/01-namespace.yaml

# Step 2: Apply deny-all policy (blocks ALL traffic in the namespace)
kubectl apply -f network-policy/01-deny-all.yaml

# Step 3: Allow DNS egress (pods NEED DNS to resolve service names)
# Without this, all wget/curl commands will fail with "bad address"
kubectl apply -f network-policy/04-allow-egress-dns.yaml

# Step 4: Allow frontend → backend INGRESS (who can come IN to backend)
kubectl apply -f network-policy/02-allow-frontend-to-backend.yaml

# Step 5: Allow frontend → backend EGRESS (where frontend can send traffic OUT)
# BOTH ingress AND egress are needed because deny-all blocks both directions
kubectl apply -f network-policy/06-allow-frontend-egress-to-backend.yaml

# Step 6: Allow ingress from ingress controller
kubectl apply -f network-policy/03-allow-ingress-only.yaml

# Step 7: Isolate namespace from other namespaces
kubectl apply -f network-policy/05-namespace-isolation.yaml

# Verify all network policies are applied
kubectl get networkpolicies -n devsecops-demo

# Describe a network policy to see its rules
kubectl describe networkpolicy deny-all -n devsecops-demo
```

### Testing Network Policies

```bash
# Deploy test pods and services (comply with restricted PSS)
kubectl apply -f network-policy/test-pods.yaml

# Wait for all pods to be Running
kubectl get pods -n devsecops-demo
kubectl get svc -n devsecops-demo

# Test 1: frontend → backend on port 8080
# Expected: SUCCESS (allowed by ingress + egress policies)
kubectl exec -it test-frontend -n devsecops-demo -- wget -qO- --timeout=3 http://test-backend:8080

# Test 2: frontend → database on port 5432
# Expected: TIMEOUT/FAIL (no egress policy allows frontend → database)
kubectl exec -it test-frontend -n devsecops-demo -- wget -qO- --timeout=3 http://test-database:5432

# Test 3: Check from default namespace (should be BLOCKED by namespace isolation)
kubectl exec -it external-pod -n default -- wget -qO- --timeout=3 http://test-backend.devsecops-demo.svc.cluster.local:8080
# Expected: TIMEOUT (namespace isolation blocks cross-namespace traffic)

# Cleanup test pods when done
kubectl delete -f network-policy/test-pods.yaml
```

### Important: How Network Policies Work Together

```
deny-all (block everything)
   +
allow-egress-dns (pods can resolve DNS names)
   +
allow-frontend-to-backend INGRESS (backend accepts traffic from frontend)
   +
allow-frontend-egress-to-backend EGRESS (frontend can send traffic to backend)
   =
frontend ──► backend ✅ (works)
frontend ──► database ❌ (blocked — no egress policy)
database ──► anyone ❌ (blocked — no egress policy)
```
```

---

## 3️⃣ Pod Security Standards (15 min)

### What are Pod Security Standards (PSS)?

Pod Security Standards define three levels of security for pods:

| Level | Purpose | Example |
|-------|---------|---------|
| **Privileged** | No restrictions (admin/system pods) | kube-system pods |
| **Baseline** | Minimal restrictions (blocks known exploits) | General workloads |
| **Restricted** | Maximum security (production workloads) | Sensitive apps |

### What Each Level Blocks

| Setting | Privileged | Baseline | Restricted |
|---------|-----------|----------|------------|
| Privileged containers | ✅ Allowed | ❌ Blocked | ❌ Blocked |
| Host networking | ✅ Allowed | ❌ Blocked | ❌ Blocked |
| Host PID/IPC | ✅ Allowed | ❌ Blocked | ❌ Blocked |
| Run as root | ✅ Allowed | ✅ Allowed | ❌ Blocked |
| Privilege escalation | ✅ Allowed | ✅ Allowed | ❌ Blocked |
| All capabilities | ✅ Allowed | Partial | ❌ Drop ALL |
| Writable root FS | ✅ Allowed | ✅ Allowed | ❌ Read-only |

### Hands-On Commands

```bash
# Apply restricted pod (follows all security best practices)
kubectl apply -f pod-security/01-restricted-pod.yaml

# Apply baseline pod (moderate security)
kubectl apply -f pod-security/02-baseline-pod.yaml

# Try to apply privileged pod (should be REJECTED if enforcement is on)
kubectl apply -f pod-security/03-privileged-pod.yaml

# Enforce Pod Security Standards on namespace
kubectl apply -f pod-security/04-namespace-enforcement.yaml

# Verify namespace labels
kubectl get namespace devsecops-demo --show-labels

# After enforcement — try deploying privileged pod again
kubectl apply -f pod-security/03-privileged-pod.yaml
# Expected: Error — pod violates PodSecurity "restricted:latest"

# Check pod security violations in events
kubectl get events -n devsecops-demo --field-selector reason=FailedCreate
```

---

## 4️⃣ Secrets Management (10 min)

### Kubernetes Secrets — The Problem

Kubernetes secrets are **base64 encoded, NOT encrypted**. Anyone with access can decode them:

```bash
# This is NOT encryption — anyone can decode it
echo "bXlfc2VjcmV0X3Bhc3N3b3Jk" | base64 --decode
# Output: my_secret_password
```

### Best Practices for Secrets

| Practice | Why |
|----------|-----|
| Enable encryption at rest | Secrets encrypted in etcd |
| Use RBAC to restrict access | Only specific SAs can read secrets |
| Don't put secrets in Git | Use sealed-secrets or external stores |
| Rotate secrets regularly | Limit exposure time |
| Use external secret stores | AWS Secrets Manager, HashiCorp Vault |

### Hands-On Commands

```bash
# Create a secret from the YAML file
kubectl apply -f secrets/01-secret-opaque.yaml

# Create Docker registry secret
kubectl apply -f secrets/02-secret-docker-registry.yaml

# Deploy pod that uses the secret as a volume
kubectl apply -f secrets/03-pod-with-secret.yaml

# Deploy pod that uses secret as environment variable
kubectl apply -f secrets/04-secret-as-env.yaml

# Verify secret is mounted in the pod
kubectl exec -it secret-demo-pod -n devsecops-demo -- cat /etc/secrets/db-password
# Expected: my_secret_password

# Verify environment variable
kubectl exec -it secret-env-pod -n devsecops-demo -- printenv DB_PASSWORD
# Expected: my_secret_password

# List secrets in namespace
kubectl get secrets -n devsecops-demo

# Describe secret (shows keys but NOT values)
kubectl describe secret app-secrets -n devsecops-demo

# Decode a secret value (proves base64 is NOT secure)
kubectl get secret app-secrets -n devsecops-demo -o jsonpath='{.data.db-password}' | base64 --decode
```

---

## 📋 Kubernetes Security Checklist

- [ ] Enable RBAC and follow least privilege
- [ ] Create service accounts for each application (don't use default)
- [ ] Disable automounting of service account tokens
- [ ] Apply network policies — deny all, then allow only needed
- [ ] Enforce Pod Security Standards (restricted level for production)
- [ ] Run pods as non-root with read-only filesystem
- [ ] Drop ALL capabilities, add only needed
- [ ] Never use privileged containers in production
- [ ] Enable encryption at rest for secrets
- [ ] Use external secret stores (Vault, AWS Secrets Manager)
- [ ] Rotate secrets regularly
- [ ] Set resource limits on all pods (CPU, memory)
- [ ] Use a CNI plugin that supports network policies (Calico/Cilium)

---

## 📚 Resources

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)

## 🎓 Free Course

- [Developing Secure Software (LFD121)](https://openssf.org/training/courses/) — Free course by OpenSSF covering secure development practices
