Perfect—this is now the most useful form of the guide: **official-aligned + AKS-ready + “why” for every step + verification included**.

Below is the **final cleaned runbook**.

---

# 🚀 Envoy Gateway on AKS (Official Helm + Internal LoadBalancer)

## 📌 What you are building

You are deploying:

* **Envoy Gateway** (Kubernetes Gateway API controller)
* **Envoy Proxy** (data plane, auto-managed)
* **Azure Internal LoadBalancer (private IP only)**
* **Gateway API routing (Gateway + HTTPRoute)**

👉 This replaces NGINX Ingress with a **standard Kubernetes-native networking model**

---

# 🧭 Architecture Flow

```text id="arch1"
Gateway API CRDs
        ↓
Envoy Gateway (Helm install)
        ↓
GatewayClass (binds controller + config)
        ↓
Gateway (creates Azure LoadBalancer)
        ↓
Envoy Proxy (data plane)
        ↓
HTTPRoute (routing rules)
        ↓
Backend service
```

---

# 📦 Prerequisites (VERIFY FIRST)

### ✔ Check cluster access

```bash id="p1"
kubectl get nodes
```

### ✔ Check Helm

```bash id="p2"
helm version
```

### ✔ Check Azure login

```bash id="p3"
az account show
```

### ✔ Check outbound internet (IMPORTANT)

```bash id="p4"
curl https://google.com
```

---

# 🚀 Step 1: Install Gateway API CRDs

## 📘 What this is

Gateway API is a **Kubernetes SIG standard networking model** that defines:

* GatewayClass (controller selection)
* Gateway (entry point)
* HTTPRoute (routing rules)

These are **not built into Kubernetes**, so they must be installed.

---

## 🧠 Why this step is needed

Without these CRDs:

* Kubernetes cannot understand Gateway resources
* Envoy Gateway cannot function at all

---

```bash id="s1"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml

customresourcedefinition.apiextensions.k8s.io/backendtlspolicies.gateway.networking.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/listenersets.gateway.networking.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/tlsroutes.gateway.networking.k8s.io configured
validatingadmissionpolicy.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io configured
validatingadmissionpolicybinding.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io configured
```

---

## 🔍 Verify

```bash id="s1v"
kubectl get crds | grep gateway

backends.gateway.envoyproxy.io                        2026-06-08T12:55:50Z
backendtlspolicies.gateway.networking.k8s.io          2026-06-08T12:55:48Z
backendtrafficpolicies.gateway.envoyproxy.io          2026-06-08T12:55:51Z
clienttrafficpolicies.gateway.envoyproxy.io           2026-06-08T12:55:52Z
envoyextensionpolicies.gateway.envoyproxy.io          2026-06-08T12:55:52Z
envoypatchpolicies.gateway.envoyproxy.io              2026-06-08T12:55:53Z
envoyproxies.gateway.envoyproxy.io                    2026-06-08T12:55:56Z
gatewayclasses.gateway.networking.k8s.io              2026-06-08T12:55:47Z
gateways.gateway.networking.k8s.io                    2026-06-08T12:55:48Z
grpcroutes.gateway.networking.k8s.io                  2026-06-08T12:55:48Z
httproutefilters.gateway.envoyproxy.io                2026-06-08T12:55:57Z
httproutes.gateway.networking.k8s.io                  2026-06-08T12:55:49Z
listenersets.gateway.networking.k8s.io                2026-06-08T12:55:47Z
referencegrants.gateway.networking.k8s.io             2026-06-08T12:55:47Z
securitypolicies.gateway.envoyproxy.io                2026-06-08T12:55:58Z
tcproutes.gateway.networking.k8s.io                   2026-06-08T12:55:47Z
tlsroutes.gateway.networking.k8s.io                   2026-06-08T12:55:48Z
udproutes.gateway.networking.k8s.io                   2026-06-08T12:55:48Z
xbackendtrafficpolicies.gateway.networking.x-k8s.io   2026-06-08T12:55:48Z
xmeshes.gateway.networking.x-k8s.io                   2026-06-08T12:55:47Z
```

---

# 🚀 Step 2: Install Envoy Gateway (Helm – Official Method)

## 📘 What this is

Installs the **Envoy Gateway controller (control plane)**:

* Watches Gateway API objects
* Creates Envoy proxy deployments
* Configures routing automatically

---

## 🧠 Why this step is needed

Without this:

* Gateway API objects exist but do nothing
* No Envoy proxy is created
* No traffic handling happens

---

```bash id="s2"
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.8.1 \
  -n envoy-gateway \
  --create-namespace \
  --set installCRDs=false \
  --set-string service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true" \
  --set-string service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet"="aks-ilb-subnet"


```
Command output:

```bash
Pulled: docker.io/envoyproxy/gateway-helm:v1.8.1
Digest: sha256:f46b2f38b695279fce81dced26d97724c3445fcccb0488aaa28ec5ef963a6181
NAME: envoy
LAST DEPLOYED: Mon Jun  8 12:56:05 2026
NAMESPACE: envoy-gateway
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
**************************************************************************
*** PLEASE BE PATIENT: Envoy Gateway may take a few minutes to install ***
**************************************************************************

Envoy Gateway is an open source project for managing Envoy Proxy as a standalone or Kubernetes-based application gateway.

Thank you for installing Envoy Gateway! 🎉

Your release is named: envoy. 🎉

Your release is in namespace: envoy-gateway. 🎉

To learn more about the release, try:

  $ helm status envoy -n envoy-gateway
  $ helm get all envoy -n envoy-gateway

To have a quickstart of Envoy Gateway, please refer to https://gateway.envoyproxy.io/latest/tasks/quickstart.

To get more details, please visit https://gateway.envoyproxy.io and https://github.com/envoyproxy/gateway.
---

## 🔍 Verify

```bash id="s2v"
kubectl get pods -n envoy-gateway
```

---

## ⏳ Wait for readiness (important)

```bash id="s2v2"
kubectl wait --for=condition=Available \
  deployment/envoy-gateway \
  -n envoy-gateway --timeout=300s
```

---

# 🚀 Step 3: Create EnvoyProxy (AKS Internal LoadBalancer config)

## 📘 What this is

Defines how Envoy is deployed in Kubernetes, including cloud-specific behavior.

---

## 🧠 Why this step is needed

By default, Azure creates a **public LoadBalancer**.

This step forces:

👉 **Internal-only LoadBalancer (private IP in VNet)**

---

```yaml id="s3"
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: internal-proxy
  namespace: envoy-gateway
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyService:
        annotations:
          service.beta.kubernetes.io/azure-load-balancer-internal: "true"
          service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "aks-appgateway"
```

```bash id="s3a"
kubectl apply -f envoyproxy.yaml

envoyproxy.gateway.envoyproxy.io/internal-proxy created
```

---

## 🔍 Verify

```bash id="s3v"
kubectl get envoyproxy -n envoy-gateway

NAME             AGE
internal-proxy   2m11s
```

---

# 🚀 Step 4: Create GatewayClass (bind controller + config)

## 📘 What this is

Defines:

* Which controller manages Gateway resources
* Which Envoy configuration to use

---

## 🧠 Why this step is needed

Without this:

* Envoy Gateway uses default config
* Your internal LB setting is ignored
* You may get a public LoadBalancer

This is the **critical binding step**

---

```yaml id="s4"
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: internal-proxy
    namespace: envoy-gateway
```

```bash id="s4a"
kubectl apply -f gatewayclass.yaml

gatewayclass.gateway.networking.k8s.io/envoy created
```

---

## 🔍 Verify

```bash id="s4v"
kubectl get gatewayclass envoy -o yaml
```

output:

```bash
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"gateway.networking.k8s.io/v1","kind":"GatewayClass","metadata":{"annotations":{},"name":"envoy"},"spec":{"controllerName":"gateway.envoyproxy.io/gatewayclass-controller","parametersRef":{"group":"gateway.envoyproxy.io","kind":"EnvoyProxy","name":"internal-proxy","namespace":"envoy-gateway"}}}
  creationTimestamp: "2026-04-25T03:34:20Z"
  generation: 1
  name: envoy
  resourceVersion: "303882"
  uid: 00090ed0-413f-4b2a-9080-5f2e361f9c74
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: internal-proxy
    namespace: envoy-gateway
status:
  conditions:
  - lastTransitionTime: "2026-04-25T03:34:20Z"
    message: Valid GatewayClass
    observedGeneration: 1
    reason: Accepted
    status: "True"
    type: Accepted
```

---

# 🚀 Step 5: Create Gateway (triggers LoadBalancer)

## 📘 What this is

Defines the **network entry point**:

* Ports (HTTP/HTTPS)
* Entry into cluster traffic flow

---

## 🧠 Why this step is needed

This is the **trigger point**:

👉 Kubernetes creates:

* Envoy proxy deployment
* Azure LoadBalancer
* Internal IP allocation

Without this step → nothing is exposed

---

```yaml id="s5"
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: internal-gateway
  namespace: gateway-system
spec:
  gatewayClassName: envoy
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: All
```

```bash id="s5a"
kubectl apply -f gateway.yaml
```

---

## 🔍 Verify

```bash id="s5v"
kubectl get gateway
```

---

# 🚀 Step 6: Verify Internal Azure LoadBalancer

## 📘 What this is

Azure provisions:

* Internal LoadBalancer
* Private IP (10.x.x.x)

---

## 🧠 Why this step is needed

Confirms:

👉 Traffic is NOT exposed publicly
👉 Only accessible inside VNet

---

```bash id="s6"
kubectl get svc -n envoy-gateway
```

---

# 🚀 Step 7: Deploy sample application

## 📘 What this is

A backend service (nginx) used to test routing.

---

## 🧠 Why this step is needed

Without a backend:

* Routing cannot be validated
* HTTPRoute has nothing to send traffic to

---

```bash id="s7"
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80
```

---

## 🔍 Verify

```bash id="s7v"
kubectl get svc nginx
```

---

# 🚀 Step 8: Create HTTPRoute (routing rules)

## 📘 What this is

Defines how traffic is routed to backend services.

---

## 🧠 Why this step is needed

This replaces Ingress rules:

* Maps URL paths → services
* Controls traffic flow inside cluster

---

```yaml id="s8"
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: nginx-route
spec:
  parentRefs:
  - name: internal-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx
      port: 80
```

```bash id="s8a"
kubectl apply -f httproute.yaml
```

---

## 🔍 Verify

```bash id="s8v"
kubectl get httproute
```

---

# 🚀 Step 9: Test internal access

## 📘 What this is

Final validation of full networking flow.

---

## 🧠 Why this step is needed

Confirms:

* Gateway is working
* Azure internal LB is active
* Routing is correctly configured

---

```bash id="s9"
curl http://<PRIVATE-IP>
```

---

## ✔ Expected output

```text id="res1"
Welcome to nginx!
```

---

# 🧠 Final Mental Model

```text id="final"
Envoy Gateway (controller)
        ↓
Gateway API (definitions)
        ↓
GatewayClass (binds config)
        ↓
Gateway (creates Azure ILB)
        ↓
Envoy Proxy (data plane)
        ↓
HTTPRoute (routing rules)
        ↓
Backend service
```

---

# 🎯 Final Takeaway

* Every step has a **specific responsibility**
* `EnvoyProxy + GatewayClass` = internal LB control
* `Gateway` = infrastructure trigger
* `HTTPRoute` = traffic rules
* Everything is **declarative and Kubernetes-native**

---

If you want next level, I can extend this into:

* 🔐 HTTPS (TLS with cert-manager + Gateway API)
* 🌐 Azure Private DNS integration
* 📊 Observability (Prometheus + Envoy metrics)
* 🔁 Migration from NGINX Ingress → Gateway API mapping

Just tell me 👍
