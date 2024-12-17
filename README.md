## A quarkus hello deployed on kubernetes using argocd

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
- Create a `.env`, set the following variables and source it
```bash
REGISTRY_USERNAME=<REGISTRY_USERNAME>
REGISTRY_PASSWORD=<REGISTRY_PASSWORD>
GITEA_TOKEN=<GITEA_TOKEN>
HELM_PROJECT_PATH=<HELM_PROJECT_PATH>
```
- Add your project to a git repository (e.g.: gitea.cnoe.localtest.me:8443, etc.)
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
 

