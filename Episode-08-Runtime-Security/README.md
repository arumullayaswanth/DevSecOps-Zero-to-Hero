# Episode 08 - Runtime Security

## 🎯 Episode Structure (1 Hour)

| # | Topic | Duration | Focus |
|---|-------|----------|-------|
| 1 | Linux Security Capabilities | 15 min | Dropping/adding capabilities, least privilege |
| 2 | Seccomp Profiles | 20 min | System call filtering, custom profiles |
| 3 | AppArmor | 15 min | Mandatory Access Control, container profiles |
| 4 | Falco — Runtime Threat Detection | 10 min | Behavioral monitoring, custom rules |

---

## 1️⃣ Linux Security Capabilities (15 min)

### What Are Capabilities?

Linux capabilities break down root's full power into smaller, distinct privileges. Instead of giving a container full root access, you grant only the specific capabilities it needs.

### Default Docker Capabilities

By default, Docker grants containers these capabilities:

| Capability | What It Allows |
|-----------|----------------|
| `CAP_CHOWN` | Change file ownership |
| `CAP_DAC_OVERRIDE` | Bypass file permission checks |
| `CAP_FSETID` | Set file SUID/SGID bits |
| `CAP_FOWNER` | Bypass permission checks for file owner |
| `CAP_MKNOD` | Create special files |
| `CAP_NET_RAW` | Use raw sockets (ping, packet sniffing) |
| `CAP_SETGID` | Change process GID |
| `CAP_SETUID` | Change process UID |
| `CAP_SETFCAP` | Set file capabilities |
| `CAP_SETPCAP` | Transfer capabilities |
| `CAP_NET_BIND_SERVICE` | Bind to ports < 1024 |
| `CAP_SYS_CHROOT` | Use chroot |
| `CAP_KILL` | Send signals to other processes |
| `CAP_AUDIT_WRITE` | Write to audit log |

### Dangerous Capabilities (Never Grant Unless Required)

| Capability | Risk |
|-----------|------|
| `CAP_SYS_ADMIN` | Near-root access — mount filesystems, namespace ops |
| `CAP_NET_ADMIN` | Modify network config, firewall rules |
| `CAP_SYS_PTRACE` | Debug/trace other processes (container escape risk) |
| `CAP_SYS_MODULE` | Load kernel modules |
| `CAP_DAC_READ_SEARCH` | Read any file on the system |

### Hands-On: Managing Capabilities

```bash
# Run container with ALL capabilities dropped
docker run --cap-drop=ALL nginx

# Drop all, then add only what's needed
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx

# Check capabilities inside a container
docker run --rm alpine sh -c "apk add -q libcap && capsh --print"

# See current capabilities of a running container
docker inspect <container> --format '{{.HostConfig.CapAdd}} {{.HostConfig.CapDrop}}'
```

### Best Practice: Drop ALL, Add Back Minimum

```bash
# ❌ BAD: Default capabilities (too many)
docker run nginx

# ❌ WORSE: Privileged mode (ALL capabilities + more)
docker run --privileged nginx

# ✅ GOOD: Drop all, add only what's needed
docker run \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --cap-add=CHOWN \
  --cap-add=SETUID \
  --cap-add=SETGID \
  nginx
```

### Capabilities in Docker Compose

```yaml
version: '3.8'
services:
  web:
    image: nginx:1.25-alpine
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
      - CHOWN
      - SETUID
      - SETGID
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
      - /var/cache/nginx
```

### Capabilities in Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  containers:
    - name: app
      image: nginx:1.25-alpine
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
          add:
            - NET_BIND_SERVICE
```

---

## 2️⃣ Seccomp Profiles (20 min)

### What Is Seccomp?

**Seccomp** (Secure Computing Mode) filters which **system calls** a container can make to the Linux kernel. If a container tries to make a blocked syscall, it gets killed.

### Why Seccomp Matters

- Containers share the host kernel — every syscall is a potential attack vector
- The Linux kernel has 300+ syscalls, most containers need < 50
- Blocking unused syscalls prevents kernel exploits

### Docker's Default Seccomp Profile

Docker ships with a default profile that blocks ~44 dangerous syscalls:

| Blocked Syscall | Risk If Allowed |
|----------------|-----------------|
| `mount` | Mount filesystems, escape container |
| `umount` | Unmount host filesystems |
| `ptrace` | Debug/inspect other processes |
| `reboot` | Reboot the host |
| `kexec_load` | Load a new kernel |
| `open_by_handle_at` | Bypass file permissions |
| `init_module` | Load kernel modules |
| `delete_module` | Remove kernel modules |
| `clock_settime` | Change system time |
| `swapon/swapoff` | Modify swap space |

### Check Current Seccomp Status

```bash
# Verify seccomp is enabled
docker info --format '{{.SecurityOptions}}'
# Output: [name=seccomp,profile=builtin ...]

# Run with default seccomp (this is the default)
docker run --security-opt seccomp=unconfined alpine cat /proc/1/status | grep Seccomp
# Seccomp: 0 (disabled)

docker run alpine cat /proc/1/status | grep Seccomp
# Seccomp: 2 (filter mode — enabled)
```

### Custom Seccomp Profile

Create a restrictive profile that only allows syscalls your app needs:

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "comment": "Custom seccomp profile - deny by default, allow only needed syscalls",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_AARCH64"
  ],
  "syscalls": [
    {
      "names": [
        "accept", "accept4", "access", "arch_prctl",
        "bind", "brk", "close", "connect",
        "dup", "dup2", "dup3",
        "epoll_create", "epoll_create1", "epoll_ctl", "epoll_wait", "epoll_pwait",
        "exit", "exit_group",
        "fcntl", "fstat", "futex",
        "getdents64", "getpid", "getppid", "getsockname", "getsockopt", "gettid",
        "ioctl",
        "listen", "lseek",
        "mmap", "mprotect", "munmap",
        "nanosleep", "newfstatat",
        "openat",
        "poll", "ppoll",
        "read", "readlink", "recvfrom", "recvmsg",
        "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
        "sendmsg", "sendto", "set_robust_list", "setsockopt",
        "shutdown", "sigaltstack", "socket",
        "stat", "statfs",
        "tgkill",
        "write", "writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### Using Custom Seccomp Profiles

```bash
# Run with custom seccomp profile
docker run --security-opt seccomp=./custom-seccomp.json nginx

# Run with NO seccomp (dangerous — for debugging only)
docker run --security-opt seccomp=unconfined nginx

# Generate a profile by tracing syscalls (using strace)
strace -c -f -S name docker run --rm nginx 2>&1 | tail -20
```

### Generating Seccomp Profiles with OCI Tools

```bash
# Use oci-seccomp-bpf-hook to auto-generate profiles
# 1. Run container with tracing
docker run --annotation io.containers.trace-syscall=of:/tmp/profile.json nginx

# 2. Use the generated profile
docker run --security-opt seccomp=/tmp/profile.json nginx
```

### Seccomp in Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/custom-seccomp.json
  containers:
    - name: app
      image: nginx:1.25-alpine
      securityContext:
        allowPrivilegeEscalation: false
```

For Kubernetes, place the profile at:
```
/var/lib/kubelet/seccomp/profiles/custom-seccomp.json
```

### Seccomp Profile Actions

| Action | Behavior |
|--------|----------|
| `SCMP_ACT_ALLOW` | Allow the syscall |
| `SCMP_ACT_ERRNO` | Block and return error (recommended default) |
| `SCMP_ACT_KILL` | Kill the process immediately |
| `SCMP_ACT_TRAP` | Send SIGSYS signal |
| `SCMP_ACT_LOG` | Allow but log (useful for auditing) |

---

## 3️⃣ AppArmor (15 min)

### What Is AppArmor?

**AppArmor** (Application Armor) is a Linux Mandatory Access Control (MAC) system that restricts what files, network, and capabilities a process can access — based on per-program profiles.

### AppArmor vs Seccomp

| Feature | Seccomp | AppArmor |
|---------|---------|----------|
| Controls | System calls | File access, network, capabilities |
| Granularity | Syscall level | Path-based rules |
| Default in Docker | Yes | Yes (docker-default profile) |
| Complexity | Lower | Higher |
| Best for | Blocking kernel exploits | Restricting file/network access |

### Docker's Default AppArmor Profile

Docker automatically applies the `docker-default` AppArmor profile which:
- Denies writing to `/proc` and `/sys`
- Denies mounting filesystems
- Denies access to sensitive `/proc` entries
- Restricts signal sending

```bash
# Check if AppArmor is enabled
sudo aa-status

# See Docker's default profile
cat /etc/apparmor.d/docker-default

# Run with default AppArmor (this is automatic)
docker run nginx

# Run with NO AppArmor (dangerous)
docker run --security-opt apparmor=unconfined nginx
```

### Custom AppArmor Profile

Create a custom profile at `/etc/apparmor.d/docker-nginx`:

```
#include <tunables/global>

profile docker-nginx flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Network access
  network inet tcp,
  network inet udp,
  network inet6 tcp,
  network inet6 udp,

  # Allow reading nginx files
  /etc/nginx/** r,
  /usr/share/nginx/** r,
  /var/log/nginx/** rw,
  /var/cache/nginx/** rw,
  /run/nginx.pid rw,

  # Allow reading SSL certificates
  /etc/ssl/** r,

  # Deny everything else
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /root/** rwx,
  deny /home/** rwx,
  deny /proc/*/mem r,
  deny /sys/** w,

  # Deny dangerous operations
  deny mount,
  deny umount,
  deny ptrace,

  # Allow executing nginx binary
  /usr/sbin/nginx ix,
  /usr/bin/nginx ix,
}
```

### Loading and Using Custom Profiles

```bash
# Load the profile
sudo apparmor_parser -r /etc/apparmor.d/docker-nginx

# Run container with custom profile
docker run --security-opt apparmor=docker-nginx nginx

# Check which profile a container is using
docker inspect <container> --format '{{.AppArmorProfile}}'

# Put profile in complain mode (log but don't enforce)
sudo aa-complain /etc/apparmor.d/docker-nginx

# Put profile back in enforce mode
sudo aa-enforce /etc/apparmor.d/docker-nginx

# Remove/unload a profile
sudo apparmor_parser -R /etc/apparmor.d/docker-nginx
```

### AppArmor Profile Modes

| Mode | Behavior |
|------|----------|
| **Enforce** | Blocks and logs violations |
| **Complain** | Allows but logs violations (for testing) |
| **Unconfined** | No restrictions (disabled) |

### AppArmor in Docker Compose

```yaml
version: '3.8'
services:
  web:
    image: nginx:1.25-alpine
    security_opt:
      - apparmor=docker-nginx
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
```

### AppArmor in Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-pod
  annotations:
    container.apparmor.security.beta.kubernetes.io/app: localhost/docker-nginx
spec:
  containers:
    - name: app
      image: nginx:1.25-alpine
      securityContext:
        allowPrivilegeEscalation: false
        runAsNonRoot: true
```

> **Note:** As of Kubernetes 1.30+, AppArmor uses the `securityContext.appArmorProfile` field instead of annotations.

---

## 4️⃣ Falco — Runtime Threat Detection (10 min)

### What Is Falco?

[Falco](https://falco.org/) by Sysdig is a cloud-native runtime security tool that detects unexpected behavior in containers and Kubernetes.

### How Falco Works

```
┌─────────────────────────────────────────────────┐
│                  Linux Kernel                     │
│  (syscalls: open, connect, exec, etc.)           │
└──────────────────────┬──────────────────────────┘
                       │ eBPF / kernel module
                       ▼
┌─────────────────────────────────────────────────┐
│                 Falco Engine                      │
│  - Captures syscall events                       │
│  - Evaluates against rules                       │
│  - Generates alerts                              │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│              Alert Outputs                        │
│  - stdout / syslog                               │
│  - Slack / PagerDuty                             │
│  - Kafka / gRPC                                  │
└─────────────────────────────────────────────────┘
```

### Installing Falco

```bash
# Helm install on Kubernetes
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true

# Docker (for testing)
docker run --rm -i -t \
  --privileged \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /proc:/host/proc:ro \
  falcosecurity/falco
```

### Falco Rules — Default Detections

Falco ships with rules that detect:

| Detection | Example |
|-----------|---------|
| Shell in container | `kubectl exec` into a pod |
| Sensitive file read | Reading `/etc/shadow` |
| Unexpected outbound connection | Container connecting to crypto mining pool |
| Privilege escalation | Process gaining new capabilities |
| Namespace change | Container escaping to host namespace |
| Binary modification | Writing to `/usr/bin` |

### Custom Falco Rules

```yaml
# Save as: falco-rules/custom-rules.yaml

# Rule 1: Detect shell spawned in container
- rule: Shell Spawned in Container
  desc: Detect shell execution inside a container
  condition: >
    spawned_process and
    container and
    proc.name in (bash, sh, zsh, dash, ksh)
  output: >
    Shell spawned in container
    (user=%user.name container=%container.name shell=%proc.name
     parent=%proc.pname cmdline=%proc.cmdline image=%container.image.repository)
  priority: WARNING
  tags: [container, shell, mitre_execution]

# Rule 2: Detect sensitive file access
- rule: Read Sensitive File in Container
  desc: Detect reading of sensitive files
  condition: >
    open_read and
    container and
    fd.name in (/etc/shadow, /etc/sudoers, /root/.ssh/authorized_keys)
  output: >
    Sensitive file read in container
    (user=%user.name file=%fd.name container=%container.name image=%container.image.repository)
  priority: CRITICAL
  tags: [container, filesystem, mitre_credential_access]

# Rule 3: Detect crypto mining
- rule: Detect Crypto Mining
  desc: Detect outbound connections to known mining pools
  condition: >
    outbound and
    container and
    fd.sip.name contains "mining" or fd.sport in (3333, 4444, 5555, 8888)
  output: >
    Possible crypto mining detected
    (container=%container.name connection=%fd.name image=%container.image.repository)
  priority: CRITICAL
  tags: [container, network, cryptomining]

# Rule 4: Detect container escape attempt
- rule: Container Escape via Mount
  desc: Detect mount syscall in container (potential escape)
  condition: >
    syscall.type = mount and
    container and
    not proc.name in (mount)
  output: >
    Mount syscall in container — possible escape attempt
    (user=%user.name container=%container.name command=%proc.cmdline)
  priority: CRITICAL
  tags: [container, escape, mitre_privilege_escalation]

# Rule 5: Detect package manager usage
- rule: Package Manager in Production Container
  desc: Package managers should not run in production
  condition: >
    spawned_process and
    container and
    proc.name in (apt, apt-get, yum, dnf, apk, pip, npm)
  output: >
    Package manager executed in container
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: ERROR
  tags: [container, software_mgmt]
```

### Testing Falco Rules

```bash
# Trigger a shell detection
kubectl exec -it <pod> -- /bin/bash

# Trigger sensitive file read
kubectl exec -it <pod> -- cat /etc/shadow

# Trigger package manager detection
kubectl exec -it <pod> -- apt-get update

# Check Falco logs
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50
```

---

## 🔒 Putting It All Together — Hardened Container

```bash
# Maximum security container run command
docker run \
  --name secure-app \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --security-opt=no-new-privileges:true \
  --security-opt seccomp=./custom-seccomp.json \
  --security-opt apparmor=docker-nginx \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid \
  --memory=512m \
  --cpus=1 \
  --pids-limit=100 \
  --user 1000:1000 \
  --network=app-network \
  -p 8080:8080 \
  myapp:latest
```

### Hardened Kubernetes Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hardened-pod
spec:
  automountServiceAccountToken: false
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: myapp:1.0.0
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
          add:
            - NET_BIND_SERVICE
      resources:
        limits:
          memory: "512Mi"
          cpu: "1"
        requests:
          memory: "256Mi"
          cpu: "500m"
      volumeMounts:
        - name: tmp
          mountPath: /tmp
  volumes:
    - name: tmp
      emptyDir:
        medium: Memory
        sizeLimit: 64Mi
```

---

## 🧪 Hands-On Lab

### Lab 1: Capabilities

```bash
# 1. Run container with default capabilities
docker run --rm alpine sh -c "apk add -q libcap && capsh --print"

# 2. Run with all capabilities dropped
docker run --rm --cap-drop=ALL alpine sh -c "apk add -q libcap && capsh --print"

# 3. Try to ping (requires CAP_NET_RAW)
docker run --rm --cap-drop=ALL alpine ping -c 1 google.com
# Expected: Operation not permitted

# 4. Add back NET_RAW
docker run --rm --cap-drop=ALL --cap-add=NET_RAW alpine ping -c 1 google.com
# Expected: Success
```

### Lab 2: Seccomp

```bash
# 1. Run with default seccomp
docker run --rm alpine cat /proc/1/status | grep Seccomp
# Expected: Seccomp: 2

# 2. Try to use unshare (blocked by default seccomp)
docker run --rm alpine unshare --map-root-user whoami
# Expected: Operation not permitted

# 3. Run without seccomp (dangerous)
docker run --rm --security-opt seccomp=unconfined alpine unshare --map-root-user whoami
# Expected: root
```

### Lab 3: Falco Detection

```bash
# 1. Deploy Falco
helm install falco falcosecurity/falco -n falco --create-namespace

# 2. Deploy a test pod
kubectl run test-pod --image=alpine -- sleep 3600

# 3. Trigger detections
kubectl exec -it test-pod -- sh
kubectl exec -it test-pod -- cat /etc/shadow

# 4. Check Falco alerts
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep -i "shell\|shadow"
```

---

## 📋 Runtime Security Checklist

- [ ] Drop ALL capabilities, add back only what's needed
- [ ] Never use `--privileged` in production
- [ ] Enable seccomp (use default or custom profile)
- [ ] Apply AppArmor profiles to containers
- [ ] Set `allowPrivilegeEscalation: false`
- [ ] Use `--read-only` filesystem
- [ ] Set `--no-new-privileges`
- [ ] Deploy Falco for runtime threat detection
- [ ] Set resource limits (memory, CPU, PIDs)
- [ ] Disable service account token auto-mount in Kubernetes
- [ ] Use network policies to restrict container communication

---

## 📚 Resources

- [Docker Security — Official Docs](https://docs.docker.com/engine/security/)
- [Linux Capabilities — man page](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Seccomp — Docker Docs](https://docs.docker.com/engine/security/seccomp/)
- [AppArmor — Docker Docs](https://docs.docker.com/engine/security/apparmor/)
- [Falco Documentation](https://falco.org/docs/)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
