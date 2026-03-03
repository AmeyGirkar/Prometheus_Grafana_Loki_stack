# Monitoring POC Deployment Guide

This repository contains the configuration for a Monitoring PoC with two microservices, Prometheus, Loki, Grafana, and Alertmanager.

## Prerequisites
- A Kubernetes cluster
- `kubectl` and `helm` installed and configured
- `git` installed and configured

## Directory Structure
- `microservices/`: Code and manifests for Service‑A (Shell/Alpine) and Service‑B (Nginx/Alpine).
- `helm/`: Helm values for the PLG stack (including sidecar config for Grafana).
## setup
```bash
git clone https://github.com/ameygirkar/Prometheus_Grafana_Loki_stack.git
cd Prometheus_Grafana_Loki_stack
```
## Quick Setup
You can use the provided automation script to set up everything (namespaces, microservices, and monitoring stack):
```bash
chmod +x setup-monitoring.sh
./setup-monitoring.sh
```

## Deployment Steps

### 1. Create Namespaces
```bash
kubectl create namespace monitoring
kubectl create namespace apps
```

### 2. Deploy Microservices
Build images for Service‑A and Service‑B, or use the provided manifests (updating the image field if necessary).
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

#### Install Prometheus Stack (upgrade if exists)
```bash
helm upgrade --install monitoring-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/kube-prometheus-stack-values.yaml
```
> **Note**: This replaces the previous `helm install prometheus-stack …` command. The release name `monitoring-stack` is used and the chart will be installed or upgraded as needed.

#### Install Loki Stack (upgrade if exists)
```bash
helm upgrade --install loki-stack grafana/loki-stack \
  --version 2.10.3 \
  --namespace monitoring \
  -f helm/loki-stack-values.yaml
```
> **Note**: This installs or upgrades Loki, enabling log collection. After deployment, ensure your microservices ship logs to Loki (e.g., via Promtail) and view them in Grafana.

#### Install Promtail (Log Collector)
```bash
helm upgrade --install promtail grafana/promtail \
  --namespace monitoring \
  -f helm/promtail-values.yaml
```

### 5. Configure Grafana (Sidecar for Loki datasource)
Grafana is enabled in the Prometheus stack and automatically discovers the Loki datasource via the Grafana sidecar (configured in `helm/kube-prometheus-stack-values.yaml`). No manual datasource creation is required.

### 6. Configure Notifications
Update `helm/kube-prometheus-stack-values.yaml` with your Teams Webhook URL and SMTP details before running the Helm command.

### 7. GitHub CI/CD (Optional)
This repository includes a GitHub Action to build and push Docker images. To use it:
1. Go to your GitHub Repository → Settings → Secrets and variables → Actions.
2. Add the following secrets:
   - `DOCKER_USERNAME`: Your Docker Hub username.
   - `DOCKER_PASSWORD`: Your Docker Hub personal access token or password.
3. The workflow will trigger automatically on pushes to the `main` branch that modify the `microservices/` directory.

## Verification & Monitoring

### 1. Access Grafana
Port‑forward to the Grafana service:
```bash
kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring
```
Login at `http://localhost:3000` with username `admin` and password `admin` (unless changed in values).

### 2. Check Application Logs (Loki)
1. Navigate to **Explore** in the sidebar.
2. Select **Loki** from the datasource dropdown.
3. Use the following LogQL queries:
   - **Service‑A Logs**: `{job="kubernetes-pods", app="service-a"}`
   - **Service‑B Logs**: `{job="kubernetes-pods", app="service-b"}`
   - **All Pod Logs**: `{job="kubernetes-pods"}`
   - **Error Filter**: `{job="kubernetes-pods"} |= "ERROR"`

### 3. Check Node-Level Logs (System Logs)
1. In the **Explore** tab (Loki datasource).
2. Use the query: `{job="varlogs"}` to see system logs from `/var/log/*.log`.
3. To see logs for a specific node: `{job="varlogs", node_name="YOUR_NODE_NAME"}`
4. To see specific system logs: `{job="varlogs", __path__="/var/log/syslog"}` or `{job="varlogs", __path__="/var/log/auth.log"}`
### 4. Metrics & Alerts
- **Prometheus**: Check the Metrics browser for `http_requests_total`.
- **Alertmanager**: Access via `kubectl port-forward svc/prometheus-stack-kube-alertmanager 9093:9093 -n monitoring`.

# Prometheus_Grafana_Loki_stack
