# A quarkus hello deployed on kubernetes using argocd

## Prerequisites

- kubectl, [podman](https://podman.io/docs/installation) & [idpbuilder](https://github.com/cnoe-io/idpbuilder?tab=readme-ov-file#getting-started)
- Quarkus [client](https://quarkus.io/get-started/)

## Instructions

- As we will deploy the Argocd applications using different namespaces, then create the following Argocd ConfigMap file
```bash
echo "apiVersion: v1
data:
  application.namespaces: user1,user2,user3,user4,user5
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: argocd-cmd-params-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cmd-params-cm
  namespace: argocd
" > argocd-cm.yaml
```
- Create a new kind cluster using idpbuilder and set the path of the ConfigMap file using the flag `-c`
```bash
idpbuilder create \
  --color \
  --name quarkus \
  -c argocd:<PROJECT_PATH>/argocd-cm.yaml
```
- Generate a `Quarkus Hello` project and add the needed extensions
```bash
rm -rf my-quarkus-hello
quarkus create app \
  --name my-quarkus-hello \
  dev.snowdrop:my-quarkus-hello:0.1.0 \
  -x helm,container-image-podman \
  --wrapper
  
cd my-quarkus-hello
```
- Edit the pom.xml to add the argocd extension
```bash
<dependency>
    <groupId>io.quarkiverse.argocd</groupId>
    <artifactId>quarkus-argocd</artifactId>
    <version>0.1.0</version>
</dependency> 
```
- Get the credentials to access the argocd and gitea servers.
```
idpbuilder get secrets
```
- Create a `.env`, set the following variables and source it
```bash
REGISTRY_USERNAME=<REGISTRY_USERNAME> // giteaAdmin
REGISTRY_PASSWORD=<REGISTRY_PASSWORD> // Use idpbuilder get secrets gitea command to got it
GITEA_TOKEN=<GITEA_TOKEN> // Use idpbuilder get secrets gitea command to got it
HELM_PROJECT_PATH=<HELM_PROJECT_PATH>
```
- Create a new gitea organization `quarkus` and repository `my-quarkus-hello` on `https://gitea.cnoe.localtest.me:8443/
- Add your project to the git repository (e.g.: gitea.cnoe.localtest.me:8443, etc.)
```bash
git init
git add .
git commit -asm "Initial commit"
git remote add origin https://$GITEA_TOKEN@gitea.cnoe.localtest.me:8443/quarkus/my-quarkus-hello.git
git push --set-upstream origin main
```
- Login to the registry
```bash
podman login \
  -u=$REGISTRY_USERNAME \
  -p=$REGISTRY_PASSWORD \
  gitea.cnoe.localtest.me:8443 \
  --tls-verify=false
```
- Build the image and push it on the registry using podman
```bash
set -x DOCKER_HOST unix:///run/user/501/podman/podman.sock
quarkus build \
  -Dquarkus.container-image.build=true \
  -Dquarkus.container-image.push=true \
  -Dquarkus.container-image.image=gitea.cnoe.localtest.me:8443/quarkus/my-quarkus-hello \
  -Dquarkus.container-image.insecure=true \
  -Dquarkus.podman.tls-verify=false
```
- Populate the helm chart like the argocd resources at the root of the project
```bash
mvn clean package \
  -Dquarkus.helm.output-directory=$HELM_PROJECT_PATH \
  -Dquarkus.container-image.image=gitea.cnoe.localtest.me:8443/quarkus/my-quarkus-hello
```
- Create a namespace for the user like `user1` and deploy the argocd resources
```bash
kubectl create ns user1
kubectl -n user1 apply -f .argocd
```
 

