# ✅ First understand what got created in AKS

You deployed:

* Envoy Gateway control plane pod = `envoy-gateway`
* Envoy data plane deployment = `envoy-gateway-system-internal-gateway-09524c6b`
* Internal Azure LoadBalancer service = `10.224.0.5`

That means Azure created:

> an **Internal Load Balancer (ILB)** inside your AKS VNet subnet.

So this IP:

```bash
10.224.0.5
```

is not random Kubernetes IP.

This is:

> Azure VNet internal frontend IP attached to Envoy proxy pods.

---

# ✅ Your complete traffic flow (VERY IMPORTANT)

When client sends request:

```bash
curl http://10.224.0.5/
```

traffic flows like this:

---

## STEP 1 — Client hits Azure Internal Load Balancer

Destination:

```bash
10.224.0.5:80
```

This IP belongs to:

```bash
service/envoy-gateway-system-internal-gateway-09524c6b
TYPE=LoadBalancer
```

Azure Internal Load Balancer receives packet.

Azure checks backend pool:

> backend pool = AKS worker nodes NICs

Then forwards traffic to one AKS node on NodePort:

```bash
80:32366/TCP
```

So Azure ILB actually sends traffic to:

```bash
<NodeIP>:32366
```

Validate logs in internal load balancer:

```bash
az monitor metrics list \
  --resource "/subscriptions/1175a59b-96b9-40b1-816d-23b7f16e38b8/resourceGroups/MC_rg-skdemo-aks_skhanaks_eastus2/providers/Microsoft.Network/loadBalancers/kubernetes-internal" \
  --metric PacketCount ByteCount SYNCount \
  --interval PT1M \
  --aggregation Total \
  --offset 5m \
  --query "value[].{Metric:name.value,Traffic:max(timeseries[0].data[].total)}" \
  -o table
---
output: If 0 then no traffic is hitting ILB, if >0 then traffic is hitting ILB and problem is likely in Envoy or backend service.
```
Metric       Traffic
-----------  ---------
PacketCount  0.0
ByteCount    0.0
SYNCount     0.0

## STEP 2 — kube-proxy catches NodePort traffic

On the selected AKS node:

```bash
NodeIP:32366
```

kube-proxy iptables/ipvs rules forward packet to:

```bash
Envoy Gateway dataplane pod
envoy-gateway-system-internal-gateway-09524c6b-59b5cb47d5-qszqp
```

Specifically to Envoy container listener port 10080 internally.

So now packet enters actual Envoy proxy.

---

## STEP 3 — Envoy proxy checks Gateway Listener

Your Gateway:

```bash
kubectl get gateway -n gateway-system
internal-gateway   envoy   10.224.0.5   PROGRAMMED=True
```

means Envoy created listener:

```text
0.0.0.0:80
```

inside Envoy.

Now Envoy asks:

> Do I have any HTTPRoute attached to this Gateway?

Yes:

```yaml
ParentRefs:
  name: internal-gateway
```

So route is attached.

---

## STEP 4 — Envoy evaluates HTTPRoute match rules

Your HTTPRoute says:

```yaml
matches:
  - path:
      type: PathPrefix
      value: /
```

Meaning:

> any incoming HTTP request path starting with `/` is accepted.

So request:

```bash
GET /
```

matches successfully.

---

## STEP 5 — Envoy chooses backendRef service

HTTPRoute backend:

```yaml
backendRefs:
- name: nginx
  port: 80
```

Envoy asks Kubernetes API (through xDS config pushed by Envoy Gateway control plane):

> what are the endpoints behind service nginx?

Kubernetes service:

```bash
service/nginx   ClusterIP 10.0.28.47
```

Endpoints = nginx pod IP (example):

```bash
10.244.x.x:80
```

Envoy does NOT send to ClusterIP usually — it load balances to pod endpoints.

So Envoy forwards request to:

```bash
nginx pod -> 10.244.x.x:80
```

---

## STEP 6 — nginx pod responds back

nginx returns HTML.

Response path:

```text
nginx pod → Envoy pod → kube-proxy → Azure ILB → client
```

---

# 🔥 Visual architecture (this will make it crystal clear)

![Image](https://images.openai.com/static-rsc-4/KRU9lFeGgR3OBS1jij1ymiDOtVuCPaGWrsW9iu8IXEBwl-nv4iJ0OwVItVI5PH_8DJUYBSPjx8ahkKSlbNPfIugpELkvKXkVPDNQ0IBKbUtzOR5hzO8-w2Wn12IUgqBIxrE6WoUpmnhVLwMfq1cNIolQadYk9CRD67pJLFz1lK1H1wXciQUEoTta_YmCeVML?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/3iB-I1rfLav6zDGSysLO9bLcFRQam09q8uFHhW966jmZWzKJhog0uYC6SgSK1d4j9qi5UQ0wDV7mho8LIDJvaOp2uSZ5wnK7w1Ns_KbSM-t_NUOzZZooT0FbKXOOfAnn0CWhicg9r2g6xMbPi6Mzx-n6Do-B1P1TwZ5x8UzSOSEj348RnyG9srIxojYnap4e?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/D8b658EiH4QBDE3LlVIbpFRtFAU_HjB8V7O2RSd9L84ksYmjVPdC38OUptherMdMFFzvGs42XJX7pAXQQbxSDi9qeTeMmIEL33lMIoGvalMaJcYErCdmzy9Hekhi0vmYn7Fc_8T4YJ91o3VITqAIEhf1MHqcvTRJGVWxr9WwSlWVhd41qV_HTVLe73CVtidp?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/7hySU-nxU2yWxhQl_trJ6FvNI2gau-Q59q57iaPbZ3KW66TCz8mNWZi0iPz5CpFDZgZhCzDc7nMTFGtAfslyRfCZUWcagC_5fF3e1hdQV2xFjSzjyeylzq4dBBFqr3RTKD9fe87dr8i3eJMcD5OAPz3CEjdop_8ttO1yD03yJahcIVoNvnhOqFW0irq2XpJ9?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/NRdx3z_vApN_Jd4MK6t86joFMRoA973aB0U9Kaegy1zP9XbG9TMSbDkV06qPf74FjbQwPfwBTlHbnDp5AcsLTCJjlfmFUQ__cBfjqLzUUyZWdWMkmpl1TB1CLPtvVS6uEDcWrq4Zbi9aN6ltb9TN7J1-xMCFIz3vAQBfA0a4oDQp9Loe21_WFMSEu0zW-Yl8?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/OrwWWNOQAJAptmqzzhFVRYeY3KgrJsbxSsER8ScOsSUWnuWHFw7SRrfjKNNWAL0_DaFzNi02a1Y2Ln2P_HvFq-PGyt4wsAZ1G5Khr3muExHS264COYnYfqAShaBn2GmAFNU65XtiEz9_TIcJFvhz9j9faj2X8PPZVyBHJjhpoxzgHFSdS1rqXBrGngxcRAE1?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/bwmwIt49MBqEFIf_xBXSwEHYnhXUvoZQUm_K4gYwsNMeeRgrOzbR1jzqKaRhm_XG4gx7yO_hFC7-GCJmNz3RRnNxr2JNcEmHL3raKvUkGCo6ACD354edByBMwdThYLXB6KckIOyXQFGHxwRjbNrQz8rgQ98shRQ504IA8mowEfyUfmaNQmVPWiQIMPmwniQ5?purpose=fullsize)

---

# ✅ So can you access it now?

YES.

From:

* any pod inside cluster
* any VM inside same Azure VNet
* peered VNet machine
* VPN connected machine

you should be able to do:

```bash
curl http://10.224.0.5
```

and get nginx welcome page.

---

# ✅ Test from your curl pod

Run:

```bash
kubectl exec -it curl -- sh
```

Inside pod:

```bash
curl -v http://10.224.0.5
```

Expected:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

---

# ✅ Why this should work already

Because all your statuses are healthy:

### GatewayClass accepted

```bash
ACCEPTED=True
```

means Envoy controller is active.

---

### Gateway programmed

```bash
PROGRAMMED=True
```

means Envoy listener + LoadBalancer service created successfully.

---

### HTTPRoute no errors

No events + attached to Gateway means route accepted.

---

### Envoy dataplane pod running

```bash
2/2 Running
```

means actual proxy is serving traffic.

---

# ✅ VERY IMPORTANT — if curl to 10.224.0.5 fails, check these 3 things

---

## 1. Check HTTPRoute status conditions

Run:

```bash
kubectl get httproute nginx-route -o yaml
```

Look for:

```yaml
status:
  parents:
  - conditions:
    - type: Accepted
      status: "True"
    - type: ResolvedRefs
      status: "True"
```

If not true → route not attached.

---

## 2. Check envoy listeners loaded

```bash
kubectl logs -n envoy-gateway-system deploy/envoy-gateway
```

should show route translation.

---

## 3. Check Azure NSG/subnet rules

Since ILB IP is VNet internal:

sometimes NSG blocks port 80 between subnets.

---

# ✅ Real production meaning of this architecture

This means:

instead of accessing app via:

```bash
curl http://10.0.28.47
```

(service ClusterIP only internal kube network)

you now access app via:

```bash
curl http://10.224.0.5
```

through enterprise-grade L7 proxy:

Envoy Proxy

which gives:

* path routing
* host routing
* retries
* rate limiting
* auth
* mTLS
* observability
* canary deployments

---

# ⭐ One SUPER IMPORTANT hidden concept AKS engineers ask in interviews

Your nginx service is still ClusterIP.

Yet externally through ILB it works.

Because:

> Envoy Gateway is becoming the single ingress point, and HTTPRoute is telling Envoy how to internally reach ClusterIP-backed pods.

This is the whole Gateway API model.

---

# ✅ Next I can show you something very valuable:

I can show you how to verify this traffic live using:

```bash
kubectl get svc,ep,endpointslice
kubectl logs envoy pod
kubectl exec curl -- curl http://10.224.0.5
```

and prove packet-by-packet that Envoy is forwarding to nginx.

Just say **continue** 👇
