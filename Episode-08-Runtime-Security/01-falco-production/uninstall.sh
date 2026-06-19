#!/bin/bash
# Uninstall Falco
echo "Uninstalling Falco..."
helm uninstall falco -n falco
kubectl delete namespace falco
echo "✅ Falco uninstalled."
