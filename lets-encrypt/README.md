# Deploy a Let’s Encrypt Wildcard Certificate Using acme.sh

This guide explains how to install acme.sh and configure it to issue wildcard certificates using Let’s Encrypt as the default Certificate Authority (CA).

Wildcard certificates allow you to secure a domain and all its subdomains (e.g., *.example.com) with a single certificate.

## Prerequisites

A Linux/Unix-based system
curl installed
Access to a domain name
DNS provider access (required later for wildcard validation via DNS challenge)

## Step 1 — Install acme.sh

acme.sh is a lightweight ACME client written in shell script. It is used to request and manage SSL/TLS certificates from Let’s Encrypt and other CAs.

### Install the Script
```bash
curl https://get.acme.sh | sh
```

This command:
Downloads the installation script
Installs acme.sh to your home directory (~/.acme.sh)
Adds an alias to your shell profile

### Reload Your Shell Environment
source ~/.bashrc


If you are using zsh, run:
```bash
source ~/.zshrc
```

Verify Installation
```bash
acme.sh --version
```

You should see the installed version number displayed, confirming the installation was successful.

## Step 2 — Set Let’s Encrypt as the Default Certificate Authority

By default, acme.sh may use another CA (such as ZeroSSL). To ensure certificates are issued by Let’s Encrypt, set it as the default CA.

### Change Default CA
```bash
acme.sh --set-default-ca --server letsencrypt
```
### Expected Output
[Thu Feb 12 04:02:36 UTC 2026] Changed default CA to: https://acme-v02.api.letsencrypt.org/directory


This confirms that Let’s Encrypt is now configured as the default CA for issuing certificates.
[Thu Feb 12 04:02:36 UTC 2026] Changed default CA to: https://acme-v02.api.letsencrypt.org/directory
## 4 Request a Wildcard Certificate
To generate a wildcard certificate, you must use the DNS challenge method. Wildcard certificates (*.domain.com) cannot be validated using HTTP challenge.

### Run the following command:
skadmin@MSI:~/lets-encrypt$ acme.sh --issue \
  -d skdemo.online \
  -d "*.skdemo.online" \
  --dns \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please
### Expected Output
[Thu Feb 12 04:02:53 UTC 2026] Using CA: https://acme-v02.api.letsencrypt.org/directory
[Thu Feb 12 04:02:53 UTC 2026] Account key creation OK.
[Thu Feb 12 04:02:53 UTC 2026] Registering account: https://acme-v02.api.letsencrypt.org/directory
[Thu Feb 12 04:02:55 UTC 2026] Registered
[Thu Feb 12 04:02:55 UTC 2026] ACCOUNT_THUMBPRINT='HJc3cB1aoxcwav1PRRj5DZL7-45XVlqolnH0Y9KrcsM'
[Thu Feb 12 04:02:55 UTC 2026] Creating domain key
[Thu Feb 12 04:02:55 UTC 2026] The domain key is here: /home/skadmin/.acme.sh/skdemo.online_ecc/skdemo.online.key
[Thu Feb 12 04:02:55 UTC 2026] Multi domain='DNS:skdemo.online,DNS:*.skdemo.online'
[Thu Feb 12 04:02:58 UTC 2026] Getting webroot for domain='skdemo.online'
[Thu Feb 12 04:02:58 UTC 2026] Getting webroot for domain='*.skdemo.online'
[Thu Feb 12 04:02:58 UTC 2026] Add the following TXT record:
[Thu Feb 12 04:02:58 UTC 2026] Domain: '_acme-challenge.skdemo.online'
[Thu Feb 12 04:02:58 UTC 2026] TXT value: 'kQ8dSOq_5V_4tq_MpmQ7zwGiMQp_LCehaHkxhUIn_ys'
[Thu Feb 12 04:02:58 UTC 2026] Please make sure to prepend '_acme-challenge.' to your domain
[Thu Feb 12 04:02:58 UTC 2026] so that the resulting subdomain is: _acme-challenge.skdemo.online
[Thu Feb 12 04:02:58 UTC 2026] Add the following TXT record:
[Thu Feb 12 04:02:58 UTC 2026] Domain: '_acme-challenge.skdemo.online'
[Thu Feb 12 04:02:58 UTC 2026] TXT value: '1g9zecvronRHMOkTnRZrZtYpD4mCZFkLYjkxEqpYy5Y'
[Thu Feb 12 04:02:58 UTC 2026] Please make sure to prepend '_acme-challenge.' to your domain
[Thu Feb 12 04:02:58 UTC 2026] so that the resulting subdomain is: _acme-challenge.skdemo.online
[Thu Feb 12 04:02:58 UTC 2026] Please add the TXT records to the domains, and re-run with --renew.
[Thu Feb 12 04:02:58 UTC 2026] Please add '--debug' or '--log' to see more information.
[Thu Feb 12 04:02:58 UTC 2026] See: https://github.com/acmesh-official/acme.sh/wiki/How-to-debug-acme.sh

## 5 Create TXT Record in DNS
Now log in to your DNS provider dashboard and create two a new TXT record as available in the output above.
| Type | Name                            | Value                            |
| ---- | ------------------------------- | -------------------------------- |
| TXT  | `_acme-challenge.skdemo.online` | `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` |
| TXT  | `_acme-challenge.skdemo.online` | `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` |

### Important Notes

TTL can be set to 120 or 300 seconds (or lowest allowed).
If both root and wildcard domains generate separate TXT values, add both records.
Do NOT remove existing records.
DNS propagation may take a few minutes depending on provider.

## 6 Verify TXT Record Propagation
Before continuing, verify that the TXT record is publicly visible.

### run the following command:
```bash
nslookup -type=TXT _acme-challenge.skdemo.online
```
### Expected Output
Server:         10.255.255.254
Address:        10.255.255.254#53

Non-authoritative answer:
_acme-challenge.skdemo.online   text = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
_acme-challenge.skdemo.online   text = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

Authoritative answers can be found from:

### If the value does not appear:
Wait a few minutes
Clear DNS cache if needed
Re-check

## 7 Request Certificate Issuance
Now that the TXT records are in place and propagated, you can proceed to request the certificate issuance

### Run the following command:
```bash
acme.sh --renew \
  -d skdemo.online \
  --dns \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please
```
### Expected Output
[Thu Feb 12 04:09:50 UTC 2026] The domain 'skdemo.online' seems to already have an ECC cert, let's use it.
[Thu Feb 12 04:09:50 UTC 2026] Renewing: 'skdemo.online'
[Thu Feb 12 04:09:50 UTC 2026] Renewing using Le_API=https://acme-v02.api.letsencrypt.org/directory
[Thu Feb 12 04:09:51 UTC 2026] Using CA: https://acme-v02.api.letsencrypt.org/directory
[Thu Feb 12 04:09:51 UTC 2026] Multi domain='DNS:skdemo.online,DNS:*.skdemo.online'
[Thu Feb 12 04:09:51 UTC 2026] Verifying: skdemo.online
[Thu Feb 12 04:09:53 UTC 2026] Pending. The CA is processing your order, please wait. (1/30)
[Thu Feb 12 04:10:00 UTC 2026] Success
[Thu Feb 12 04:10:00 UTC 2026] Verifying: *.skdemo.online
[Thu Feb 12 04:10:01 UTC 2026] Pending. The CA is processing your order, please wait. (1/30)
[Thu Feb 12 04:10:05 UTC 2026] Success
[Thu Feb 12 04:10:05 UTC 2026] Verification finished, beginning signing.
[Thu Feb 12 04:10:05 UTC 2026] Let's finalize the order.
[Thu Feb 12 04:10:05 UTC 2026] Le_OrderFinalize='https://acme-v02.api.letsencrypt.org/acme/finalize/3055274696/479345692246'
[Thu Feb 12 04:10:09 UTC 2026] Downloading cert.
[Thu Feb 12 04:10:09 UTC 2026] Le_LinkCert='https://acme-v02.api.letsencrypt.org/acme/cert/0532328419bfc3f3f7ed4ab1d5d202d3bad7'
[Thu Feb 12 04:10:10 UTC 2026] Cert success.
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
[Thu Feb 12 04:10:10 UTC 2026] Your cert is in: /home/skadmin/.acme.sh/skdemo.online_ecc/skdemo.online.cer
[Thu Feb 12 04:10:10 UTC 2026] Your cert key is in: /home/skadmin/.acme.sh/skdemo.online_ecc/skdemo.online.key
[Thu Feb 12 04:10:10 UTC 2026] The intermediate CA cert is in: /home/skadmin/.acme.sh/skdemo.online_ecc/ca.cer
[Thu Feb 12 04:10:10 UTC 2026] And the full-chain cert is in: /home/skadmin/.acme.sh/skdemo.online_ecc/fullchain.cer

#### If validation succeeds, the certificate will be issued.
Certificates will be stored in: ~/.acme.sh/skdemo.online/

## 6 Install Certificate in specific directory for Use in AKS cluster

Now that you have the certificate, you can install it for use with your web server or application. The following example shows how to install the certificate for a domain.

#### Run the following command:
```bash
acme.sh --install-cert -d skdemo.online \
--key-file       ~/certs-letsencrypt/tls.key \
--fullchain-file ~/certs-letsencrypt/tls.crt
```
### Expected Output
[Thu Feb 12 04:12:30 UTC 2026] Installing cert to:/home/skadmin/certs-letsencrypt/tls.crt
[Thu Feb 12 04:12:30 UTC 2026] Installing key to:/home/skadmin/certs-letsencrypt/tls.key
[Thu Feb 12 04:12:30 UTC 2026] Installing full chain cert to:/home/skadmin/certs-letsencrypt/fullchain.crt
[Thu Feb 12 04:12:30 UTC 2026] Installing CA cert to:/home/skadmin/certs-letsencrypt/ca.cer

## 7 Create Kubernetes TLS Secret with the Certificate
After successfully generating the wildcard certificate using acme.sh, the next step is to create a Kubernetes TLS secret so it can be used by an Ingress controller (e.g., NGINX Ingress) or other Kubernetes workloads.

#### Kubernetes expects:
tls.crt → Full certificate chain
tls.key → Private key

### Run the following command to create the TLS secret:
```bash
kubectl create secret tls skdemo-wildcard-cert \
  --cert=/home/skadmin/certs-letsencrypt/tls.crt \
  --key=/home/skadmin/certs-letsencrypt/tls.key \
  -n envoy-gateway
```
### Expected Output

secret/skdemo-wildcard-cert created

## 8 Create gateway  to use the certificate for secure communication with the application. 

```bash
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
  namespace: envoy-gateway
spec:
  gatewayClassName: envoy
  listeners:

    - name: https
      port: 443
      protocol: HTTPS
      hostname: "*.skdemo.online"
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: skdemo-wildcard-cert
      allowedRoutes:
        namespaces:
          from: All

    - name: http
      port: 80
      protocol: HTTP
      hostname: "*.skdemo.online"
      allowedRoutes:
        namespaces:
          from: All
```


## 9 Application http route to route the traffic to the application.

### create httproute yaml file with the following content and apply it to the cluster.

```bash
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: moon-route
  namespace: moon
spec:
  parentRefs:
    - name: envoy-gateway
      namespace: envoy-gateway
  hostnames:
    - "moon.skdemo.online"
  rules:
    - backendRefs:
        - name: moon-service
          port: 80
```