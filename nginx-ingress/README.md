# Deploy NGINX Ingress Controller in AKS with Internal Private IP

(With detailed explanation of every step and why we do it)

---

# What We Are Building

We will deploy:

```text id="2jvq4e"
Client (Internal Network/VPN)
        ↓
Azure Internal Load Balancer (Private IP)
        ↓
NGINX Ingress Controller
        ↓
Ingress Rules
        ↓
Kubernetes Service
        ↓
Application Pods
```

Instead of exposing applications to the internet using a Public IP, we will expose them only inside the private network using an Azure Internal Load Balancer (ILB).

---

# Why Use Internal NGINX Ingress?

Use Internal Ingress when applications should only be accessible:

* Inside corporate network
* Over VPN
* Through ExpressRoute
* Inside private VNets
* For backend/internal APIs
* For internal portals

Examples:

| Application               | Public or Internal? |
| ------------------------- | ------------------- |
| Banking Admin Portal      | Internal            |
| Internal APIs             | Internal            |
| HR Management Portal      | Internal            |
| Public E-commerce Website | Public              |

---

# Step 1 — Connect kubectl to AKS Cluster

## Command

```bash id="l73d1f"
az aks get-credentials \
  --resource-group rg-demo \
  --name aks-demo
```

---

# Why Are We Doing This?

AKS cluster exists inside Azure.

Your local machine does NOT automatically know:

* Which AKS cluster to connect to
* Authentication details
* Kubernetes API endpoint

This command:

* Downloads cluster credentials
* Updates kubeconfig file
* Allows kubectl to talk to AKS

---

# What Happens Internally?

Azure CLI:

1. Connects to Azure ARM API
2. Retrieves AKS kubeconfig
3. Merges it into:

```text id="vcb9gl"
~/.kube/config
```

4. kubectl now knows:

   * Cluster endpoint
   * Certificates
   * Authentication token

---

# Expected Output

```text id="snz3n7"
Merged "aks-demo" as current context in /home/user/.kube/config
```

---

# Verify Connection

## Command

```bash id="ibzucq"
kubectl get nodes
```

---

# Why?

We verify:

* kubectl connectivity works
* Cluster API is reachable
* Worker nodes are healthy

---

# Expected Output

```text id="j00f52"
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-xxxx-vmss000000      Ready    agent   12d   v1.30.x
aks-nodepool1-xxxx-vmss000001      Ready    agent   12d   v1.30.x
```

---

# Understanding Output

| Column  | Meaning              |
| ------- | -------------------- |
| NAME    | AKS node VM          |
| STATUS  | Node health          |
| ROLES   | Worker node          |
| AGE     | How long node exists |
| VERSION | Kubernetes version   |

---

# Step 2 — Create Namespace

## Command

```bash id="gzy8vl"
kubectl create namespace ingress-nginx
```

---

# Why Are We Creating Namespace?

Namespaces logically separate Kubernetes resources.

Without namespace:

* Everything goes into `default`
* Hard to manage
* Hard to troubleshoot
* Risk of naming conflicts

We create dedicated namespace for ingress controller.

---

# Benefits of Separate Namespace

| Benefit           | Explanation                  |
| ----------------- | ---------------------------- |
| Isolation         | Separate from applications   |
| Easier management | Easier cleanup               |
| RBAC              | Easier permission management |
| Monitoring        | Easier filtering             |

---

# Expected Output

```text id="rjlwmn"
namespace/ingress-nginx created
```

---

# Step 3 — Add NGINX Helm Repository

## Command

```bash id="0sxk5l"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

---

# Why Are We Doing This?

Helm is Kubernetes package manager.

Like:

| Technology | Package Manager |
| ---------- | --------------- |
| Ubuntu     | apt             |
| Python     | pip             |
| Node.js    | npm             |
| Kubernetes | Helm            |

The repo contains:

* NGINX ingress templates
* Kubernetes manifests
* Configuration defaults

Without adding repo:

Helm does not know where to download ingress package.

---

# Expected Output

```text id="5zvb13"
"ingress-nginx" has been added to your repositories
```

---

# Step 4 — Update Helm Repository

## Command

```bash id="sz1f5x"
helm repo update
```

---

# Why?

This downloads latest chart metadata.

Without this:

* Helm may use old versions
* Missing latest fixes
* Compatibility issues

---

# Expected Output

```text id="h5b4w3"
Update Complete.
```

---

# Step 5 — Install NGINX Ingress with Internal Load Balancer

## Command

```bash id="o3d0rj"
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true"
```

---

# This Is the Most Important Step

This command installs:

* NGINX ingress controller pods
* Service account
* RBAC permissions
* Admission webhooks
* Kubernetes service
* Azure Load Balancer integration

---

# Understanding the Command

---

## Part 1

```bash id="nd83x9"
helm install
```

Meaning:

Install Helm chart into Kubernetes cluster.

---

## Part 2

```bash id="u1vx6h"
ingress-nginx
```

This is Helm release name.

Like application instance name.

---

## Part 3

```bash id="s33hpf"
ingress-nginx/ingress-nginx
```

Meaning:

```text id="5g6cdz"
<repo-name>/<chart-name>
```

Helm downloads ingress controller chart from repository.

---

## Part 4

```bash id="p4o2zn"
--namespace ingress-nginx
```

Install everything into namespace:

```text id="p7b7eu"
ingress-nginx
```

---

## Part 5 (MOST IMPORTANT)

```bash id="8u9kr6"
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true"
```

---

# Why This Annotation Matters

Normally AKS creates:

```text id="25j8z6"
Public Azure Load Balancer
```

because Kubernetes service type is:

```text id="jlwmjp"
LoadBalancer
```

But we want:

```text id="w6z1p8"
Private Internal Load Balancer
```

This annotation tells AKS Cloud Controller Manager:

```text id="h5i9md"
"Create internal load balancer instead of public."
```

---

# What Happens Internally?

AKS cloud provider performs:

1. Calls Azure API
2. Creates Internal Load Balancer
3. Allocates private IP
4. Creates backend pool
5. Adds AKS nodes
6. Configures health probes
7. Creates LB rules

---

# Expected Output

```text id="j2xj76"
NAME: ingress-nginx
LAST DEPLOYED: Fri May 8
NAMESPACE: ingress-nginx
STATUS: deployed
```

---

# Step 6 — Verify Pods

## Command

```bash id="c5tbg9"
kubectl get pods -n ingress-nginx
```

---

# Why?

We verify:

* Pods are running
* Images downloaded
* Controller healthy
* No crash loops

---

# Expected Output

```text id="rmsi3x"
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-xxxx              1/1     Running   0          2m
```

---

# Understanding Output

| Column   | Meaning            |
| -------- | ------------------ |
| READY    | Containers healthy |
| STATUS   | Pod state          |
| RESTARTS | Crashes            |
| AGE      | Running duration   |

---

# Step 7 — Verify Service

## Command

```bash id="g5d4s6"
kubectl get svc -n ingress-nginx
```

---

# Why?

This is where Azure Load Balancer gets created.

Service type:

```text id="1a3w5y"
LoadBalancer
```

triggers AKS to create Azure LB.

---

# Expected Output

```text id="0lqvme"
NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)
ingress-nginx-controller   LoadBalancer   10.0.10.20   10.224.0.25   80:32456/TCP,443:32011/TCP
```

---

# Important Understanding

Even though column says:

```text id="2y5ixg"
EXTERNAL-IP
```

it is actually:

```text id="ic5t7h"
Private IP
```

because Azure Internal LB still exposes frontend IP.

---

# Traffic Flow Now

```text id="0o9jlwm"
Internal Client
       ↓
10.224.0.25
       ↓
Azure Internal LB
       ↓
NGINX Controller Pod
```

---

# Step 8 — Deploy Application

## Deployment YAML

```yaml id="dxyzyr"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: nginx
        ports:
        - containerPort: 80
```

---

# Why Deployment?

Deployment manages pods.

Without Deployment:

* Pods are not self-healing
* No scaling
* No rolling updates

Deployment ensures:

```text id="6h78ku"
Always keep 2 nginx pods running
```

---

# Apply Deployment

```bash id="4e1l8m"
kubectl apply -f deployment.yaml
```

---

# Expected Output

```text id="xjtv4j"
deployment.apps/demo-app created
```

---

# Step 9 — Create Service

## YAML

```yaml id="bks1l9"
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  selector:
    app: demo-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

---

# Why Service Needed?

Pods are temporary.

Pod IPs change.

Ingress cannot directly connect to pods.

Service provides:

* Stable DNS
* Stable IP
* Load balancing to pods

---

# Why ClusterIP?

We do NOT want app exposed directly.

Only ingress should expose app.

So service remains internal inside cluster.

---

# Traffic Flow

```text id="nx8tvl"
Ingress
   ↓
Service
   ↓
Pods
```

---

# Apply Service

```bash id="gwlc9m"
kubectl apply -f service.yaml
```

---

# Expected Output

```text id="4v7im2"
service/demo-service created
```

---

# Step 10 — Create Ingress Resource

## YAML

```yaml id="k7f7rf"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
spec:
  ingressClassName: nginx

  rules:
  - host: internal.demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-service
            port:
              number: 80
```

---

# Why Ingress Resource?

Ingress defines routing rules.

Without ingress:

NGINX controller does not know:

* Which hostname
* Which path
* Which backend service

---

# What This Rule Means

```text id="9s5ltw"
If request comes for:
internal.demo.local

Forward to:
demo-service
```

---

# Apply Ingress

```bash id="22jnix"
kubectl apply -f ingress.yaml
```

---

# Expected Output

```text id="21jq81"
ingress.networking.k8s.io/demo-ingress created
```

---

# Step 11 — Verify Ingress

## Command

```bash id="5vhv4o"
kubectl get ingress
```

---

# Expected Output

```text id="7uqzqj"
NAME           CLASS   HOSTS                 ADDRESS       PORTS
demo-ingress   nginx   internal.demo.local   10.224.0.25  80
```

---

# What Happened Internally?

NGINX controller:

1. Watches Kubernetes API
2. Detects new ingress
3. Generates nginx.conf
4. Reloads NGINX dynamically

---

# Generated NGINX Config Conceptually

```nginx id="2g0d1w"
server {
    server_name internal.demo.local;

    location / {
        proxy_pass http://demo-service;
    }
}
```

---

# Step 12 — Configure DNS/Hosts

## Why?

Your laptop does not know:

```text id="fjlwm9"
internal.demo.local
```

We manually map hostname to private IP.

---

# Linux

```bash id="c7bx7m"
sudo nano /etc/hosts
```

Add:

```text id="v5u9jv"
10.224.0.25 internal.demo.local
```

---

# Windows

```text id="jlwm2i"
C:\Windows\System32\drivers\etc\hosts
```

Add same entry.

---

# Step 13 — Test Application

## Command

```bash id="fjlwm3"
curl http://internal.demo.local
```

---

# Expected Output

```html id="o0q9ms"
<title>Welcome to nginx!</title>
```

---

# Full End-to-End Flow

```text id="jkgfbc"
User Browser
     ↓
DNS Resolution
     ↓
10.224.0.25
     ↓
Azure Internal Load Balancer
     ↓
NGINX Ingress Controller
     ↓
Ingress Rule
     ↓
demo-service
     ↓
demo-app pod
```

---

# Why This Architecture Is Powerful

Benefits:

| Feature            | Benefit              |
| ------------------ | -------------------- |
| Single Entry Point | One LB for many apps |
| Path Routing       | /app1, /app2         |
| Host Routing       | app1.company.local   |
| TLS Centralization | HTTPS at ingress     |
| Load Balancing     | Across pods          |
| Internal Security  | No public exposure   |

---

# Common Production Enhancements

Most enterprises also add:

| Feature           | Purpose             |
| ----------------- | ------------------- |
| Azure Private DNS | Internal DNS        |
| cert-manager      | Auto TLS            |
| Key Vault         | Secure certificates |
| Prometheus        | Monitoring          |
| HPA               | Autoscaling         |
| WAF               | Security            |
