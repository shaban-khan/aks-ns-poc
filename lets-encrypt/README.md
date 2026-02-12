

## Deploy Let's encypt
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

### Verify
kubectl get pods -n cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-77f7698dcf-gb9gm              1/1     Running   0          2m22s
cert-manager-cainjector-557b97dd67-49br7   1/1     Running   0          2m23s
cert-manager-webhook-5b7654ff4-lvw5d       1/1     Running   0          2m21s

### Create Manual ClusterIssuer

This tells cert-manager:

“I will handle DNS TXT records myself.”

clusterissuer-manual.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-manual
spec:
  acme:
    email: admin@skdemo.online
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-manual-account-key
    solvers:
    - dns01:
        manual: {}


Apply:

kubectl apply -f clusterissuer-manual.yaml


Verify:

kubectl get clusterissuer letsencrypt-manual


Expected:

READY   True