#!/bin/bash

# Monitoring & Argo CD Setup Script
# This script automates the installation of the Monitoring stack and Argo CD.

set -e

NAMESPACE_MONITORING="monitoring"
NAMESPACE_APPS="apps"
ARGOCD_NAMESPACE="argocd"

echo "--------------------------------------------------"
echo "1. Creating Namespaces (monitoring, apps, argocd)..."
echo "--------------------------------------------------"
kubectl create namespace $NAMESPACE_MONITORING --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_APPS --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "--------------------------------------------------"
echo "2. Adding Helm Repositories..."
echo "--------------------------------------------------"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "--------------------------------------------------"
echo "3. Installing Argo CD..."
echo "--------------------------------------------------"
kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n $ARGOCD_NAMESPACE -p '{"spec": {"type": "NodePort"}}'

echo "--------------------------------------------------"
echo "4. Installing Loki Stack..."
echo "--------------------------------------------------"
helm upgrade --install loki-stack grafana/loki-stack \
  --namespace $NAMESPACE_MONITORING \
  -f helm/loki-stack-values.yaml

echo "--------------------------------------------------"
echo "4.5 Provisioning Loki Datasource via Sidecar..."
echo "--------------------------------------------------"
kubectl apply -f helm/loki-datasource.yaml

echo "--------------------------------------------------"
echo "5. Installing Prometheus Stack..."
echo "--------------------------------------------------"
helm upgrade --install monitoring-stack prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE_MONITORING \
  -f helm/kube-prometheus-stack-values.yaml

echo "--------------------------------------------------"
echo "6. Installing Promtail..."
echo "--------------------------------------------------"
helm upgrade --install promtail grafana/promtail \
  --namespace $NAMESPACE_MONITORING \
  -f helm/promtail-values.yaml

echo "--------------------------------------------------"
echo "7. Waiting for Argo CD Server to be Ready..."
echo "--------------------------------------------------"
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n $ARGOCD_NAMESPACE --timeout=300s

echo "--------------------------------------------------"
echo "8. Applying Argo CD Application manifests (Service A & B)..."
echo "--------------------------------------------------"
kubectl apply -f argocd/applications/service-a.yaml
kubectl apply -f argocd/applications/service-b.yaml

echo "--------------------------------------------------"
echo "9. Retrieving Argo CD Admin Password..."
echo "--------------------------------------------------"
ARGOCD_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "--------------------------------------------------"
echo "SETUP COMPLETE"
echo "--------------------------------------------------"
echo "GRAFANA (admin/admin):"
echo "  URL: http://<NODE_IP>:31244 (NodePort)"
echo "  Port-forward: kubectl port-forward svc/monitoring-stack-grafana 3000:80 -n $NAMESPACE_MONITORING"
echo ""
echo "ARGO CD (admin / $ARGOCD_PASSWORD):"
echo "  URL: http://<NODE_IP>:$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}') (NodePort)"
echo "  Port-forward: kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
echo ""
echo "Check Logs in Grafana (Explore -> Loki):"
echo "  Service A: {job=\"kubernetes-pods\", app=\"service-a\"}"
echo "  Service B: {job=\"kubernetes-pods\", app=\"service-b\"}"
echo "  Node Logs: {job=\"varlogs\"}"
echo "--------------------------------------------------"
