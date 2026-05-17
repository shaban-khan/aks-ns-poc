# Deploying Envoy Gateway API support offline

## 1. Deploy the Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
customresourcedefinition.apiextensions.k8s.io/backendtlspolicies.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/listenersets.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/tlsroutes.gateway.networking.k8s.io created
validatingadmissionpolicy.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io created
validatingadmissionpolicybinding.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io created
validatingwebhookconfiguration.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io created
```
Output:

```bash
skadmin@MSI:~$ kubectl get crds | grep gateway
backendtlspolicies.gateway.networking.k8s.io     2026-05-16T13:56:08Z
gatewayclasses.gateway.networking.k8s.io         2026-05-16T13:56:09Z
gateways.gateway.networking.k8s.io               2026-05-16T13:56:10Z
grpcroutes.gateway.networking.k8s.io             2026-05-16T13:56:11Z
httproutes.gateway.networking.k8s.io             2026-05-16T13:56:13Z
listenersets.gateway.networking.k8s.io           2026-05-16T13:56:15Z
referencegrants.gateway.networking.k8s.io        2026-05-16T13:56:15Z
tlsroutes.gateway.networking.k8s.io              2026-05-16T13:56:16Z
skadmin@MSI:~$
```
## 2. Make available Envoy Gateway images in ACR

### - Eport the images used by Envoy Gateway

```bash
export IMAGES=(
docker.io/envoyproxy/envoy:v1.35.0
docker.io/envoyproxy/gateway:v1.8.0
docker.io/envoyproxy/ratelimit:master
)
```
### - Pull the images in online machine
```bash
for img in "${IMAGES[@]}"; do
  docker pull $img
done
```
### - Save images into a single tar file in online machine
```bash
docker save -o envoy-images.tar ${IMAGES[@]}
```
### - Copy the tar file to offline machine
```bash
scp envoy-images.tar user@offline-vm:/tmp/
```

### - Load the images from tar file in offline machine
```bash
docker load -i /tmp/envoy-images.tar
```
Verify:
```bash
docker images | grep envoyproxy
envoyproxy/envoy                     v1.35.0              cfe1c570e72a        2 weeks ago         238MB
envoyproxy/gateway                   v1.8.0               a9b4c4d8a402        2 weeks ago         326MB
envoyproxy/ratelimit                 master               625874071453        2 weeks ago         38.9MB
```
### - Tag and push the images
```bash
export ACR_NAME=skhanacr
export ACR_LOGIN_SERVER=skhanacr-bje4amcrcbfxbcg8.azurecr.io

docker tag envoyproxy/envoy:v1.35.0 \
  $ACR_LOGIN_SERVER/envoyproxy/envoy:v1.35.0
docker tag envoyproxy/gateway:v1.8.0 \
  $ACR_LOGIN_SERVER/envoyproxy/gateway:v1.8.0
docker tag envoyproxy/ratelimit:master \
  $ACR_LOGIN_SERVER/envoyproxy/ratelimit:master
```
### - Push the images to ACR
```bash
az acr login --name $ACR_NAME
Login Succeeded

docker push $ACR_LOGIN_SERVER/envoyproxy/envoy:v1.35.0
docker push $ACR_LOGIN_SERVER/envoyproxy/gateway:v1.8.0
docker push $ACR_LOGIN_SERVER/envoyproxy/ratelimit:master
```
### - Verify the images are in ACR
```bash
az acr repository list --name $ACR_NAME --output table
```

## 3. Download Helm chart (online machine)

### - Update the Helm repository
```bash
helm repo add envoyproxy https://helm.envoyproxy.io
helm repo update
```
### - Pull the Helm chart for Envoy Gateway

```bash
helm pull oci://docker.io/envoyproxy/gateway-helm \
  --version 1.8.0 \
  --untar

helm show values oci://docker.io/envoyproxy/gateway-helm \
  --version 1.8.0 > values.yaml

helm template envoy-gateway ./gateway-helm > rendered.yaml
cp gateway-helm/values.yaml values.yaml
```

## 3. Deploy Envoy Gateway using Helm

### - Update the image references in values.yaml to point to the ACR images
```yaml
images:
  gateway:
    repository: skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/gateway
    tag: v1.8.0
  envoy:
    repository: skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/envoy
    tag: v1.35.0
  ratelimit:
    repository: skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/ratelimit
    tag: master
```
### - Deploy Envoy Gateway using Helm

```bash
helm install envoy-gateway ./gateway-helm \
  --namespace envoy-gateway-system \
  --create-namespace \
  -f values.yaml
```


```bash
docker push skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/gateway:v1.8.0
docker push envoyproxy/gateway:v1.8.0 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/gateway:v1.8.0
docker push skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/ratelimit:05c08d03
docker push envoyproxy/ratelimit:05c08d03 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/ratelimit:05c08d03
docker push envoyproxy/envoy:v1.35.0 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/envoy:v1.35.0
docker push envoyproxy/gateway:v1.8.0 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/gateway:v1.8.0
docker push envoyproxy/ratelimit:05c08d03 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/ratelimit:05c08d03

docker tag envoyproxy/envoy:v1.35.0 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/envoy:v1.35.0
docker tag envoyproxy/ratelimit:05c08d03 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/ratelimit:05c08d03
docker tag envoyproxy/gateway:v1.8.0 skhanacr-bje4amcrcbfxbcg8.azurecr.io/thirdparty/envoyproxy/gateway:v1.8.0
grep -oP '(?<=image: ).*' rendered.yaml | sort -u
helm template envoy-gateway ./gateway-helm > rendered.yaml

```bash
helm install envoy-gateway ./gateway-helm   
    --namespace envoy-gateway-system   
    --create-namespace   
    -f values.yaml

Output:

```bash
NAME: envoy-gateway
LAST DEPLOYED: Sat May 16 14:02:31 2026
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

Your release is named: envoy-gateway. 🎉

Your release is in namespace: envoy-gateway-system. 🎉

To learn more about the release, try:

  $ helm status envoy-gateway -n envoy-gateway-system
  $ helm get all envoy-gateway -n envoy-gateway-system

To have a quickstart of Envoy Gateway, please refer to https://gateway.envoyproxy.io/latest/tasks/quickstart.

To get more details, please visit https://gateway.envoyproxy.io and https://github.com/envoyproxy/gateway.
```
## 3. Verify the installation

```bash
kubectl get pods -n envoy-gateway-system
NAME                             READY   STATUS    RESTARTS   AGE
envoy-gateway-5b75d4bd94-m456z   1/1     Running   0          2m
```
```bash
kubectl get svc -n envoy-gateway-system
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                                            AGE
envoy-gateway   ClusterIP   10.0.150.233   <none>        18000/TCP,18001/TCP,18002/TCP,19001/TCP,9443/TCP   3m38s
```
## 4. Envoy Proxy configuration

```bash
kubectl apply -f config-manifest-files/envoyproxy.yaml
envoyproxy.gateway.envoyproxy.io/gateway-configuration created
```
```bash
kubectl apply -f config-manifest-files/gateway-class.yaml
gatewayclass.gateway.networking.k8s.io/envoy created
```
```bash
kubectl apply -f config-manifest-files/gateway.yaml
gateway.gateway.networking.k8s.io/envoy-gateway created
```
## 5. Verify the Gateway and its associated resources

```bash
kubectl get gateway -n envoy-gateway-system
NAME            CLASS   ADDRESS      PROGRAMMED   AGE
envoy-gateway   envoy   10.224.0.5   True         5m1s
```
```bash
kubectl get envoyproxy -n envoy-gateway-system
NAME                    AGE
gateway-configuration   11m
```
```bash
kubectl get gatewayclass
NAME    CONTROLLER                                      ACCEPTED   AGE
envoy   gateway.envoyproxy.io/gatewayclass-controller   True       8m13s
```

## 6. Deploying Sample Nginx Test Application


## 7. Create HTTPRoute to route traffic to the test application