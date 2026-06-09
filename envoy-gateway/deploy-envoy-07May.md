# Deploy Envoy Gateway using Helm on 07 May 2026
## 1. Install Envoy Gateway using Helm

```bash
helm install envoy \
oci://docker.io/envoyproxy/gateway-helm \
--version 1.7.2 \
--namespace envoy-gateway-system \
--create-namespace
```

### Expected Output

```text
Pulled: docker.io/envoyproxy/gateway-helm:1.7.2
Digest: sha256:040a7de3452961b0cdb4cad25c10bc403f842d85cb8567691bc8f7b33bcde7c8
NAME: envoy
LAST DEPLOYED: Thu May  7 02:30:10 2026
NAMESPACE: envoy-gateway-system
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

Your release is in namespace: envoy-gateway-system. 🎉

To learn more about the release, try:

  $ helm status envoy -n envoy-gateway-system
  $ helm get all envoy -n envoy-gateway-system

To have a quickstart of Envoy Gateway, please refer to https://gateway.envoyproxy.io/latest/tasks/quickstart.

To get more details, please visit https://gateway.envoyproxy.io and https://github.com/envoyproxy/gateway.
**************************************************************************
```
---
### Verify the Installation

```bash
kubectl get all -n envoy-gateway-system
```
#### Sample Output

```text
kubectl get all -n envoy-gateway-system
NAME                                 READY   STATUS    RESTARTS   AGE
pod/envoy-gateway-6d8dcc9f79-6rg87   1/1     Running   0          2m1s

NAME                    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                            AGE
service/envoy-gateway   ClusterIP   10.0.182.92   <none>        18000/TCP,18001/TCP,18002/TCP,19001/TCP,9443/TCP   2m1s

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/envoy-gateway   1/1     1            1           2m2s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/envoy-gateway-6d8dcc9f79   1         1         1       2m2s
```
This confirms the Envoy Gateway controller is running successfully.
---
## 2. Create the Envoy GatewayClass
The `GatewayClass` defines Envoy as the controller that manages Gateway resources.
### Create `gateway-class.yaml`

```yaml
