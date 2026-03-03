# Monitoring POC Deployment Guide

This repository contains the configuration for a Monitoring POC with Two Microservices, Prometheus, Loki, Grafana, and Alertmanager.

## Prerequisites
- A Kubernetes cluster
- `kubectl` and `helm` installed and configured

## Directory Structure
- `microservices/`: Code and manifests for Service-A (Shell/Alpine) and Service-B (Nginx/Alpine).
- `helm/`: Helm values for PLG stack.

## Deployment Steps

### 1. Create Namespaces
```bash
kubectl create namespace monitoring
kubectl create namespace apps
```

### 2. Deploy Microservices
Build images for Service-A and Service-B, or use the provided manifests (updating the image field if necessary).
```bash
kubectl apply -f microservices/service-b/k8s/manifests.yaml
kubectl apply -f microservices/service-a/k8s/manifests.yaml
```

### 3. Install PLG Stack
Add Helm repositories:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install Prometheus Stack:
```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/kube-prometheus-stack-values.yaml
```

Install Loki Stack:
```bash
helm install loki-stack grafana/loki-stack \
  --namespace monitoring \
  -f helm/loki-stack-values.yaml
```

### 4. Configure Notifications
Update `helm/kube-prometheus-stack-values.yaml` with your Teams Webhook URL and SMTP details before running the `helm install` command.

## Verification
- **Grafana**: Port-forward to Grafana service and log in.
- **Loki**: Check logs in Grafana Explore tab using the Loki datasource.
- **Alertmanager**: Trigger a failure in Service-B and verify alert generation.
# Prometheus_Grafana_Loki_stack
