# End-to-End Envoy Gateway Traffic Validation Flow in AKS

Assume:

* Internal LB IP = `10.10.4.25`
* Namespace = `envoy-gateway-system`
* Backend app namespace = `default`
* Gateway name = `eg`
* HTTPRoute name = `my-route`
* Backend service = `myapp`
* Backend pod = `myapp-xxxxx`

---

# Full Request Flow

```text id="s3qk6j"
Client VM
   ↓
Azure Internal Load Balancer
   ↓
Envoy Service (K8s LoadBalancer Service)
   ↓
Envoy Proxy Pod
   ↓
Gateway Listener Match
   ↓
HTTPRoute Match
   ↓
Cluster Selection
   ↓
Kubernetes Service
   ↓
Backend Pod
```

---

# STEP 1 — Client VM → Azure Internal Load Balancer

## Purpose

Validate:

* Internal LB reachable
* NSG allows traffic
* Azure networking works
* Envoy Service exposed properly

---

## Command

Run from VM inside same VNet:

```bash id="mslg5e"
curl -v http://10.10.4.25
```

---

# What Happens

Client sends HTTP request to:

```text id="z1thji"
10.10.4.25
```

This IP belongs to Azure Internal Load Balancer.

---

# Expected Output

```text id="d7tms2"
* Connected to 10.10.4.25
> GET / HTTP/1.1
> Host: 10.10.4.25
>
< HTTP/1.1 200 OK
< server: envoy
```
Real output:

```text
curl -v http://10.224.0.5
*   Trying 10.224.0.5:80...
* Connected to 10.224.0.5 (10.224.0.5) port 80
> GET / HTTP/1.1
> Host: 10.224.0.5
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< server: nginx/1.30.0
< date: Fri, 08 May 2026 04:07:35 GMT
< content-type: text/html
< content-length: 896
< last-modified: Tue, 14 Apr 2026 13:10:11 GMT
< etag: "69de3cb3-380"
< accept-ranges: bytes
< 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy, 
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional 
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
* Connection #0 to host 10.224.0.5 left intact
```
---

# Validation Success Means

| Validation      | Meaning                 |
| --------------- | ----------------------- |
| TCP connected   | LB reachable            |
| HTTP 200        | Envoy processed request |
| `server: envoy` | Request reached Envoy   |

---

# If Failure Happens

| Error              | Possible Cause         |
| ------------------ | ---------------------- |
| Connection timeout | NSG/routing issue      |
| Connection refused | Service/listener issue |
| 503                | Backend unavailable    |

---

# STEP 2 — Azure ILB → Envoy Service

## Purpose

Validate:

* Azure LB targets Kubernetes service correctly
* Service mapped to Envoy pods

---

# Command

Check Envoy service:

```bash id="eokqri"
kubectl get svc -n envoy-gateway-system
```

---

# Expected Output

```text id="skdzz7"
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP
envoy     LoadBalancer   10.0.120.15    10.10.4.25
```

---

# Explanation

| Field             | Meaning                 |
| ----------------- | ----------------------- |
| TYPE=LoadBalancer | Azure LB created        |
| EXTERNAL-IP       | Internal LB IP          |
| CLUSTER-IP        | Internal K8s service IP |

---

# Deep Validation

Describe service:

```bash id="9wsppc"
kubectl describe svc envoy -n envoy-gateway-system
```

---

# Important Section

```text id="ttx6ot"
Selector:
  app.kubernetes.io/name=envoy

Endpoints:
  10.244.1.15:10080
  10.244.2.20:10080
```

Real output:

```text
kubectl describe svc envoy -n envoy-gateway-system
Name:                     envoy-envoy-gateway-system-envoy-gateway-dc2b3bc0
Namespace:                envoy-gateway-system
Labels:                   app.kubernetes.io/component=proxy
                          app.kubernetes.io/managed-by=envoy-gateway
                          app.kubernetes.io/name=envoy
                          gateway.envoyproxy.io/owning-gateway-name=envoy-gateway
                          gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system
Annotations:              service.beta.kubernetes.io/azure-load-balancer-internal: true
                          service.beta.kubernetes.io/azure-load-balancer-internal-subnet: aks-subnet
Selector:                 app.kubernetes.io/component=proxy,app.kubernetes.io/managed-by=envoy-gateway,app.kubernetes.io/name=envoy,gateway.envoyproxy.io/owning-gateway-name=envoy-gateway,gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.59.165
IPs:                      10.0.59.165
LoadBalancer Ingress:     10.224.0.5 (VIP)
Port:                     http-80  80/TCP
TargetPort:               10080/TCP
NodePort:                 http-80  31387/TCP
Endpoints:                10.244.1.193:10080,10.244.1.10:10080
Session Affinity:         None
External Traffic Policy:  Local
Internal Traffic Policy:  Cluster
HealthCheck NodePort:     31868
Events:                   <none>

Name:                     envoy-gateway
Namespace:                envoy-gateway-system
Labels:                   app.kubernetes.io/instance=envoy
                          app.kubernetes.io/managed-by=Helm
                          app.kubernetes.io/name=gateway-helm
                          app.kubernetes.io/version=v1.7.2
                          control-plane=envoy-gateway
                          helm.sh/chart=gateway-helm-1.7.2
Annotations:              meta.helm.sh/release-name: envoy
                          meta.helm.sh/release-namespace: envoy-gateway-system
Selector:                 app.kubernetes.io/instance=envoy,app.kubernetes.io/name=gateway-helm,control-plane=envoy-gateway
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.182.92
IPs:                      10.0.182.92
Port:                     grpc  18000/TCP
TargetPort:               18000/TCP
Endpoints:                10.244.1.217:18000
Port:                     ratelimit  18001/TCP
TargetPort:               18001/TCP
Endpoints:                10.244.1.217:18001
Port:                     wasm  18002/TCP
TargetPort:               18002/TCP
Endpoints:                10.244.1.217:18002
Port:                     metrics  19001/TCP
TargetPort:               19001/TCP
Endpoints:                10.244.1.217:19001
Port:                     webhook  9443/TCP
TargetPort:               9443/TCP
Endpoints:                10.244.1.217:9443
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
---

# Validation Success Means

| Validation          | Meaning                         |
| ------------------- | ------------------------------- |
| Endpoints populated | Service connected to Envoy pods |
| Pod IPs visible     | Traffic forwarded correctly     |

---

# STEP 3 — Envoy Service → Envoy Proxy Pod

## Purpose

Validate:

* Request reached Envoy pod
* Envoy accepted incoming request

---

# Command

Find Envoy pod:

```bash id="j5b6tn"
kubectl get pods -n envoy-gateway-system -o wide
```


---

# Example Output

```text id="1jsgjw"
NAME                                READY   STATUS
envoy-default-6d7f8d9c7f-abcde     2/2     Running
```


# Stream Logs

```bash id="yb0n6j"
kubectl logs -n envoy-gateway-system -f envoy-default-6d7f8d9c7f-abcde
```

Real output:

```text
kubectl get pods -n envoy-gateway-system -o wide
NAME                                                              READY   STATUS    RESTARTS   AGE   IP             NODE                                NOMINATED NODE   READINESS GATES
envoy-envoy-gateway-system-envoy-gateway-dc2b3bc0-86656cb4c6msn   2/2     Running   0          23h   10.244.1.10    aks-agentpool-89087564-vmss00000c   <none>           <none>
envoy-envoy-gateway-system-envoy-gateway-dc2b3bc0-86656cb4wz8vb   2/2     Running   0          24h   10.244.1.193   aks-agentpool-89087564-vmss00000c   <none>           <none>
envoy-gateway-6d8dcc9f79-slncz                                    1/1     Running   0          24h   10.244.1.217   aks-agentpool-89087564-vmss00000c   <none>           <none>
```

---

# Generate Traffic Again

```bash id="7ebh8v"
curl http://10.10.4.25
```

---

# Expected Logs

```text id="33z6h9"
[2026-05-08T10:15:21.123Z] "GET / HTTP/1.1" 200 - via_upstream
```

---

# Validation Success Means

| Log Part     | Meaning               |
| ------------ | --------------------- |
| GET /        | Request reached Envoy |
| 200          | Request successful    |
| via_upstream | Forwarded to backend  |

---

# STEP 4 — Gateway Listener Match

## Purpose

Validate:

* Envoy listener configured properly
* Port and protocol active

---

# Command

```bash id="5zh37f"
kubectl get gateway -A
```

---

# Example Output

```text id="wo6dvv"
NAME   CLASS   ADDRESS      PROGRAMMED
eg     eg      10.10.4.25   True
```

Real output:

```text
kubectl get gateway -A
NAMESPACE              NAME            CLASS   ADDRESS      PROGRAMMED   AGE
envoy-gateway-system   envoy-gateway   envoy   10.224.0.5   True         24h
```
---

# Detailed Validation

```bash id="p7xmqv"
kubectl describe gateway eg -n default
```

---

# Important Section

```text id="78d6rc"
Listeners:
  Name: http
  Port: 80
  Protocol: HTTP

Conditions:
  Type: Programmed
  Status: True
```

---

# Validation Success Means

| Validation      | Meaning                 |
| --------------- | ----------------------- |
| Programmed=True | Envoy accepted listener |
| Port 80 active  | Listener active         |

---

# STEP 5 — HTTPRoute Match

## Purpose

Validate:

* Route attached successfully
* URL/path matched

---

# Command

```bash id="2c4rsl"
kubectl get httproute -A
```

---

# Detailed Validation

```bash id="z69u4g"
kubectl describe httproute my-route -n default
```

---

# Expected Output

```text id="xfrqiv"
Parents:
  Conditions:
    Type: Accepted
    Status: True
```

---

# Route Rules Example

```text id="yolb39"
Rules:
  Matches:
    Path: /
```

Real output:

```text
k describe httproute nginx-route -n demo
Name:         nginx-route
Namespace:    demo
Labels:       <none>
Annotations:  <none>
API Version:  gateway.networking.k8s.io/v1
Kind:         HTTPRoute
Metadata:
  Creation Timestamp:  2026-05-07T03:51:39Z
  Generation:          2
  Resource Version:    2588200
  UID:                 f178b256-b67a-4770-bc93-c16495a41e20
Spec:
  Parent Refs:
    Group:      gateway.networking.k8s.io
    Kind:       Gateway
    Name:       envoy-gateway
    Namespace:  envoy-gateway-system
  Rules:
    Backend Refs:
      Group:
      Kind:    Service
      Name:    nginx-service
      Port:    80
      Weight:  1
    Matches:
      Path:
        Type:   PathPrefix
        Value:  /
Status:
  Parents:
    Conditions:
      Last Transition Time:  2026-05-08T04:07:31Z
      Message:               Route is accepted
      Observed Generation:   2
      Reason:                Accepted
      Status:                True
      Type:                  Accepted
      Last Transition Time:  2026-05-08T04:07:31Z
      Message:               Resolved all the Object references for the Route
      Observed Generation:   2
      Reason:                ResolvedRefs
      Status:                True
      Type:                  ResolvedRefs
    Controller Name:         gateway.envoyproxy.io/gatewayclass-controller
    Parent Ref:
      Group:      gateway.networking.k8s.io
      Kind:       Gateway
      Name:       envoy-gateway
      Namespace:  envoy-gateway-system
Events:           <none>

---

# Validation Success Means

| Validation       | Meaning                   |
| ---------------- | ------------------------- |
| Accepted=True    | Route attached to Gateway |
| Path rule exists | URL matching active       |

---

# STEP 6 — Cluster Selection

## Purpose

Validate:

* Envoy selected backend cluster
* Upstream chosen properly

---

# Command

Exec into Envoy pod:

```bash id="n2k9cx"
kubectl exec -it -n envoy-gateway-system envoy-default-6d7f8d9c7f-abcde -- sh
```

---

# Check Envoy Config

```bash id="11um1o"
curl localhost:19000/config_dump
```

---

# Search for Cluster

```bash id="uhd8nq"
curl localhost:19000/config_dump | grep myapp
```

---

# Expected Output

```text id="3xen7p"
"default/myapp"
```

---

# Explanation

Envoy internally creates clusters representing backend services.

---

# Validation Success Means

| Validation           | Meaning                    |
| -------------------- | -------------------------- |
| Cluster exists       | Backend service registered |
| Service name visible | Route connected correctly  |

---

# STEP 7 — Kubernetes Service

## Purpose

Validate:

* Backend service exists
* Endpoints populated

---

# Command

```bash id="a96r0n"
kubectl get svc
kubectl get endpoints
```

---

# Example

```bash id="3r7kmn"
kubectl get endpoints myapp
```

---

# Expected Output

```text id="v6uj1m"
NAME    ENDPOINTS
myapp   10.244.1.12:8080
```

---

# Validation Success Means

| Validation     | Meaning            |
| -------------- | ------------------ |
| Pod IP visible | Backend registered |
| Port visible   | Service healthy    |

---

# Failure Example

```text id="9x0mgx"
myapp   <none>
```

Means:

* Pods not ready
* Label mismatch
* Service selector incorrect

Envoy usually returns:

```text id="wxz9ua"
503 Service Unavailable
```

---

# STEP 8 — Backend Pod Validation

## Purpose

Validate:

* Request finally reached backend pod

---

# Command

Find pod:

```bash id="0lw8r4"
kubectl get pods -o wide
```

---

# Stream Backend Logs

```bash id="xpkq2q"
kubectl logs -f myapp-xxxxx
```

---

# Generate Traffic Again

```bash id="mwv1i0"
curl http://10.10.4.25
```

---

# Expected Output

```text id="8pq6u5"
10.244.0.15 - - [08/May/2026] "GET / HTTP/1.1" 200
```

---

# Validation Success Means

| Validation      | Meaning                    |
| --------------- | -------------------------- |
| Request visible | Backend received traffic   |
| HTTP 200        | App processed successfully |

---

# STEP 9 — Real-Time End-to-End Validation

Best practice is using 3 terminals.

---

# Terminal 1 — Envoy Logs

```bash id="w8v0yl"
kubectl logs -n envoy-gateway-system -f envoy-default-xxxxx
```

User this command to see logs:

```bash id="yb0n6j"
kubectl logs -n envoy-gateway-system \
--tail=5 \
-c envoy \
envoy-envoy-gateway-system-envoy-gateway-dc2b3bc0-86656cb4c6msn \
| jq .
```
Real output:

```text
{
  ":authority": "10.224.0.5",
  "bytes_received": 0,
  "bytes_sent": 896,
  "connection_termination_details": null,
  "downstream_local_address": "10.244.1.10:10080",
  "downstream_remote_address": "10.224.0.7:49916",
  "duration": 1,
  "method": "GET",
  "protocol": "HTTP/1.1",
  "requested_server_name": null,
  "response_code": 200,
  "response_code_details": "via_upstream",
  "response_flags": "-",
  "route_name": "httproute/demo/nginx-route/rule/0/match/0/*",
  "start_time": "2026-05-08T04:08:52.539Z",
  "upstream_cluster": "httproute/demo/nginx-route/rule/0",
  "upstream_host": "10.244.1.95:80",
  "upstream_local_address": "10.244.1.10:60448",
  "upstream_transport_failure_reason": null,
  "user-agent": "curl/8.5.0",
  "x-envoy-origin-path": "/",
  "x-envoy-upstream-service-time": null,
  "x-forwarded-for": "10.224.0.7",
  "x-request-id": "8046a128-142c-455e-af0a-cd6c64823e95"
}
---

# Terminal 2 — Backend Logs

```bash id="rtz2lh"
kubectl logs -f myapp-xxxxx
kubectl logs -n demo --tail=5 nginx-pod
```

Real output:

```text
10.244.1.193 - - [08/May/2026:04:34:24 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8.5.0" "10.224.0.7"
10.244.1.193 - - [08/May/2026:04:41:03 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8.5.0" "10.224.0.7"
10.244.1.10 - - [08/May/2026:04:42:03 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8.5.0" "10.224.0.7"
10.244.1.10 - - [08/May/2026:04:42:08 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8.5.0" "10.224.0.7"
10.244.1.10 - - [08/May/2026:04:42:11 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8.5.0" "10.224.0.7"

---

# Terminal 3 — Generate Traffic

```bash id="4p0a5u"
while true; do
  curl http://10.10.4.25
  sleep 2
done
```

---

# Expected Flow

## Envoy Logs

```text id="o2g49f"
GET / HTTP/1.1 200 via_upstream
```

## Backend Logs

```text id="p85g2t"
GET / HTTP/1.1 200
```

This proves:

```text id="i0p0wy"
Client
→ Azure ILB
→ Envoy Service
→ Envoy Pod
→ Gateway
→ HTTPRoute
→ Backend Service
→ Backend Pod
```

working end-to-end successfully.

---

# STEP 10 — Advanced Packet Validation (Optional)

## Tcpdump inside Envoy Pod

```bash id="j1w10o"
kubectl exec -it -n envoy-gateway-system envoy-default-xxxxx -- tcpdump -i any port 80
```

---

# Expected Output

```text id="qshhji"
IP 10.0.0.4 > 10.244.1.15: Flags [P.]
```

---

# Why Useful

Validates:

* Actual packets entering Envoy
* Real network traffic
* Low-level debugging

---

# Summary Table

| Step | Component         | Validation Command         |
| ---- | ----------------- | -------------------------- |
| 1    | Client → ILB      | curl                       |
| 2    | ILB → Service     | kubectl describe svc       |
| 3    | Service → Envoy   | kubectl logs               |
| 4    | Gateway Listener  | kubectl describe gateway   |
| 5    | HTTPRoute         | kubectl describe httproute |
| 6    | Cluster Selection | config_dump                |
| 7    | K8s Service       | kubectl get endpoints      |
| 8    | Backend Pod       | kubectl logs               |
| 9    | Full Live Flow    | multiple terminals         |
| 10   | Packet Level      | tcpdump                    |
