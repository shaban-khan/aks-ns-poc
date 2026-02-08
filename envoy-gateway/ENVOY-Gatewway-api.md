# Deploy Envoy Gateway API in a Public AKS Cluster

This guide explains how to deploy **Envoy Gateway** in an **Azure Kubernetes Service (AKS)** cluster using **Helm** and the **Kubernetes Gateway API**.

---

## Prerequisites

- An active AKS cluster
- `kubectl` configured to access the cluster
- Helm v3 installed
- Gateway API CRDs installed in the cluster

---

## 1. Deploy the Envoy Gateway Controller

Install Envoy Gateway using the official Helm chart.

```bash
helm install envoy oci://docker.io/envoyproxy/gateway-helm \
  --version v1.3.3 \
  --namespace envoy-gateway \
  --create-namespace
````

### Expected Output

```text
Pulled: docker.io/envoyproxy/gateway-helm:v1.3.3
Digest: sha256:f29dd79f61c17aba4b4d1c996138c473f5846f8a27f5216e36c2f21bd2cc7ce4
NAME: envoy
LAST DEPLOYED: Sat Feb  7 16:17:28 2026
NAMESPACE: envoy-gateway
STATUS: deployed
REVISION: 1
```

> **Note:** Envoy Gateway may take a few minutes to install and become ready.

Envoy Gateway is an open-source project that manages Envoy Proxy as a Kubernetes-native application gateway.

---

### Verify the Installation

```bash
kubectl get all -n envoy-gateway
```

#### Sample Output

```text
NAME                                 READY   STATUS    RESTARTS   AGE
pod/envoy-gateway-7b5758dbf9-k96pm   1/1     Running   0          35m

NAME                    TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                                   AGE
service/envoy-gateway   ClusterIP   10.0.22.75   <none>        18000/TCP,18001/TCP,18002/TCP,19001/TCP   35m

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/envoy-gateway   1/1     1            1           35m
```

This confirms the Envoy Gateway controller is running successfully.

---

## 2. Create the Envoy GatewayClass

The `GatewayClass` defines Envoy as the controller that manages Gateway resources.

### Create `gateway-class.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

### Apply the GatewayClass

```bash
kubectl apply -f gateway-class.yaml
```

---

## 3. Deploy the Envoy Gateway

The `Gateway` resource defines how traffic enters the cluster.

### Create `gateway.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
  namespace: envoy-gateway
spec:
  gatewayClassName: envoy
  listeners:
    - name: http
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
```

### Apply the Gateway

```bash
kubectl apply -f gateway.yaml
```

### Gateway Behavior

* Exposes HTTP traffic on port **80**
* Uses the **Envoy GatewayClass**
* Accepts routes from **all namespaces**
* Acts as the main ingress point for services

---

## Uninstall Envoy Gateway

To completely remove Envoy Gateway from the cluster:

### Uninstall the Helm Release

```bash
helm uninstall envoy -n envoy-gateway
```

Output:

```text
release "envoy" uninstalled
```

### Delete the Namespace

```bash
kubectl delete namespace envoy-gateway
```

Output:

```text
namespace "envoy-gateway" deleted
```

---
