#!/bin/bash

# Monitoring POC Setup and Verification Script
# This script automates the installation of the Monitoring stack and verifies the deployment.

set -e

NAMESPACE_MONITORING="monitoring"
NAMESPACE_APPS="apps"

echo "--------------------------------------------------"
echo "1. Creating Namespaces..."
echo "--------------------------------------------------"
kubectl create namespace $NAMESPACE_MONITORING --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_APPS --dry-run=client -o yaml | kubectl apply -f -

echo "--------------------------------------------------"
echo "2. Adding Helm Repositories..."
echo "--------------------------------------------------"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "--------------------------------------------------"
echo "3. Deploying Microservices..."
echo "--------------------------------------------------"
kubectl apply -f microservices/service-b/k8s/manifests.yaml
kubectl apply -f microservices/service-a/k8s/manifests.yaml

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
echo "7. Verifying Deployment..."
echo "--------------------------------------------------"
echo "Waiting for pods to be ready (this may take a few minutes)..."
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE_MONITORING --timeout=300s
kubectl get pods -n $NAMESPACE_MONITORING
kubectl get pods -n $NAMESPACE_APPS

echo ""
echo "--------------------------------------------------"
echo "SETUP COMPLETE"
echo "--------------------------------------------------"
echo "To access Grafana (admin/admin):"
echo "kubectl port-forward svc/monitoring-stack-grafana 3000:80 -n $NAMESPACE_MONITORING"
echo ""
echo "Check Application Logs in Grafana (Explore -> Loki):"
echo "  {job=\"kubernetes-pods\", app=\"service-a\"}"
echo ""
echo "Check Node Logs in Grafana (Explore -> Loki):"
echo "  {job=\"varlogs\"}"
echo "--------------------------------------------------"
