#!/bin/bash
# ============================================================
# Falco Production Installation
# This is how companies deploy Falco on their K8s clusters
# ============================================================

set -e

echo "==========================================="
echo "  Installing Falco - Production Setup"
echo "==========================================="

# Step 1: Add Falco Helm repo
echo "[1/4] Adding Falco Helm repository..."
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Step 2: Create namespace
echo "[2/4] Creating falco namespace..."
kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -

# Step 3: Install Falco with production values
echo "[3/4] Installing Falco with production configuration..."
helm upgrade --install falco falcosecurity/falco \
  --namespace falco \
  --values values-production.yaml \
  --wait \
  --timeout 5m

# Step 4: Verify installation
echo "[4/4] Verifying Falco installation..."
echo ""
echo "Falco Pods:"
kubectl get pods -n falco
echo ""
echo "Falco DaemonSet:"
kubectl get daemonset -n falco
echo ""

echo "==========================================="
echo "  ✅ Falco installed successfully!"
echo "==========================================="
echo ""
echo "Next steps:"
echo "  1. Check logs:  kubectl logs -n falco -l app.kubernetes.io/name=falco -f"
echo "  2. Run attack:  bash attack-simulation.sh"
echo "  3. Sidekick UI: kubectl port-forward -n falco svc/falco-falcosidekick-ui 2802:2802"
