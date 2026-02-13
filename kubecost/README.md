To implement **Kubecost** on your **AKS cluster**, follow this complete step-by-step guide.

Kubecost helps you monitor:

* Pod / namespace cost
* Node cost
* Idle cost
* Cluster efficiency
* Azure billing integration

---

# ✅ Step 1 — Prerequisites

Make sure:

* AKS cluster is running
* You have `kubectl` access
* `helm` installed
* Metrics Server is running:

```bash
kubectl get deployment metrics-server -n kube-system
```

If not installed:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

# ✅ Step 2 — Add Kubecost Helm Repo

```bash
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo update
```

---

# ✅ Step 3 — Create Namespace

```bash
kubectl create namespace kubecost
```

---

# ✅ Step 4 — Install Kubecost (Free Version)

For AKS, use this recommended install:

```bash
helm upgrade --install kubecost kubecost/cost-analyzer \
  --namespace kubecost \
  --version 2.8.4 \
  --set global.clusterId="aks-skdemo-poc" \
  --set kubecostToken="free-tier" \
  --set prometheus.server.persistentVolume.enabled=falsego
```

> This installs:

* Kubecost UI
* Embedded Prometheus
* Azure pricing integration (basic)

---

# ✅ Step 5 — Verify Pods

```bash
kubectl get pods -n kubecost
```

Wait until all pods are Running.

---

# ✅ Step 6 — Access Kubecost UI

### Option A — Port Forward (Quick Test)

```bash
kubectl port-forward --namespace kubecost deployment/kubecost-cost-analyzer 9090
```

Open:

```
http://localhost:9090
```

---

### Option B — Expose via LoadBalancer (Production)

```bash
kubectl expose deployment kubecost-cost-analyzer \
  --namespace kubecost \
  --type=LoadBalancer \
  --port=9090
```

Get external IP:

```bash
kubectl get svc -n kubecost
```

---

# ✅ Step 7 — Connect Azure Billing (Important for Real Cost)

For accurate AKS cost from Azure:

1. Go to **Azure Portal**
2. Subscriptions → Cost Management + Billing
3. Create **Service Principal**
4. Assign:

   * Reader
   * Cost Management Reader

Then configure in Kubecost Helm:

```bash
--set kubecostProductConfigs.azureBilling.enabled=true
--set kubecostProductConfigs.azureBilling.clientID=<appId>
--set kubecostProductConfigs.azureBilling.clientSecret=<password>
--set kubecostProductConfigs.azureBilling.tenantID=<tenantId>
--set kubecostProductConfigs.azureBilling.subscriptionID=<subscriptionId>
```

Upgrade:

```bash
helm upgrade kubecost kubecost/cost-analyzer \
  --namespace kubecost \
  -f values.yaml
```

---

# ✅ Step 8 — What You’ll See in UI

## Overview Dashboard

![Image](https://docs.aws.amazon.com/images/guidance/latest/cloud-intelligence-dashboards/images/kubecost_containers_cost_allocation.png)

![Image](https://user-images.githubusercontent.com/4100493/165348971-87fa554c-8467-49da-9883-107ffb99fc89.png)

![Image](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/media/kubecost-dashboard.png)

You’ll get:

* Namespace cost breakdown
* Pod cost
* Node cost
* Idle cost
* Efficiency score
* Historical trends

---

# ✅ Step 9 — (Optional) Integrate with Azure AD (Enterprise)

If you want SSO with Entra ID (Azure AD), Kubecost supports OIDC configuration.

---

# ✅ Step 10 — Production Best Practices for AKS

For serious usage in production:

* Enable persistent Prometheus storage
* Use Azure Managed Prometheus (optional)
* Restrict access via Ingress (Envoy Gateway in your case)
* Enable network policies
* Store secrets in Azure Key Vault

---

# 🔥 Recommended for Your Setup (Since You Use Envoy Gateway)

Instead of LoadBalancer, create HTTPRoute + Gateway for Kubecost service.

Example:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: kubecost
  namespace: kubecost
spec:
  parentRefs:
  - name: envoy-gateway
    namespace: envoy-gateway
  hostnames:
  - "kubecost.skdemo.online"
  rules:
  - backendRefs:
    - name: kubecost-cost-analyzer
      port: 9090
```

---

# 🎯 What Kubecost Helps You With in AKS

* Show which namespace is expensive
* Detect over-provisioned workloads
* Track dev vs prod spending
* Show idle nodes
* Optimize Azure VM SKU selection
* Reduce AKS monthly bill

---

If you want, I can next provide:

* 🔐 Secure setup with TLS via Let's Encrypt
* 📊 Integration with Azure Managed Prometheus
* 🏢 Enterprise multi-cluster setup
* 🧠 Cost optimization strategy for AKS

Tell me which direction you want 🚀
