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
  --version v1.8.1 \
  --namespace envoy-gateway \
  --create-namespace
```

```bash
kubectl wait --timeout=5m -n envoy-gateway deployment/envoy-gateway --for=condition=Available
```

### Expected Output

```text
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
