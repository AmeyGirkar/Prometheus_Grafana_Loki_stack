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

### 5. GitHub CI/CD (Optional)
This repository includes a GitHub Action to build and push Docker images. To use it:
1. Go to your GitHub Repository -> Settings -> Secrets and variables -> Actions.
2. Add the following secrets:
   - `DOCKER_USERNAME`: Your Docker Hub username.
   - `DOCKER_PASSWORD`: Your Docker Hub personal access token or password.
3. The workflow will trigger automatically on pushes to the `main` branch that modify the `microservices/` directory.

## Verification & Monitoring

### 1. Access Grafana
Port-forward to the Grafana service:
```bash
kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring
```
Login at `http://localhost:3000` with username `admin` and password `admin` (unless changed in values).

### 2. Check Application Logs (Loki)
1. Navigate to **Explore** in the sidebar.
2. Select **Loki** from the datasource dropdown.
3. Use the following LogQL queries:
   - **Service-A Logs**: `{namespace="apps", pod=~"service-a.*"}`
   - **Service-B Logs**: `{namespace="apps", pod=~"service-b.*"}`
   - **Error Filter**: `{namespace="apps"} |= "ERROR"`

### 3. Check Node Level Logs
1. In the **Explore** tab (Loki datasource).
2. Use the query: `{job="kubernetes-pods-static"}` or `{container="kube-proxy"}` to see system logs.
3. To see logs for a specific node: `{node_name="YOUR_NODE_NAME"}`

### 4. Metrics & Alerts
- **Prometheus**: Check Metrics browser for `http_requests_total`.
- **Alertmanager**: Access via `kubectl port-forward svc/prometheus-stack-kube-alertmanager 9093:9093 -n monitoring`.

# Prometheus_Grafana_Loki_stack
