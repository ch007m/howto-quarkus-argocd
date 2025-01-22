# Quarkus & Argo CD

How to guide explaining how to create a Quarkus application and to deploy it using the GitOps Argo CD way on a cluster using an idpbuilder platform.

## Prerequisites

- [podman](https://podman-desktop.io/) or docker desktop installed
- kubectl, [podman](https://podman.io/docs/installation) & [idpbuilder](https://github.com/cnoe-io/idpbuilder?tab=readme-ov-file#getting-started)
- Quarkus [client](https://quarkus.io/get-started/)

## Instructions

- As we will deploy our Argocd application in [any namespaces](https://argo-cd.readthedocs.io/en/stable/operator-manual/app-any-namespace/), then it is needed to configure Argo CD using the parameter `application.namespaces` to watch namespaces.
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
- Create a new kind cluster using idpbuilder and set the path to the Argo CD ConfigMap file you created using the flag `-c`
```bash
idpbuilder create \
  --color \
  --name quarkus \
  -c argocd:<PROJECT_PATH>/argocd-cm.yaml
```
- It could be needed to roll out the Argo CD pods to take care of the ConfigMap change
```bash
kubectl rollout restart -n argocd deployment argocd-server
kubectl rollout restart -n argocd statefulset argocd-application-controller 
```
- Generate now a `Quarkus Hello` project and include the extensions: helm, container-image-podman to build but also generate the YAML resources
```bash
rm -rf my-quarkus-hello
quarkus create app \
  --name my-quarkus-hello \
  --wrapper \
  dev.snowdrop:my-quarkus-hello:0.1.0 \
  -x helm,container-image-podman
  
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
- Create a new gitea organization `quarkus` and repository `my-quarkus-hello` on `https://gitea.cnoe.localtest.me:8443/`
```bash
curl -k -X POST \
  "https://gitea.cnoe.localtest.me:8443/api/v1/orgs" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -u "$REGISTRY_USERNAME:$REGISTRY_PASSWORD" \
  -d '{"username": "quarkus"}'

curl -k \
  "https://gitea.cnoe.localtest.me:8443/api/v1/orgs/quarkus/repos" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -u "$REGISTRY_USERNAME:$REGISTRY_PASSWORD" \
  -d '{
     "auto_init": false,
     "default_branch": "main",
     "description": "my-quarkus-hello",
     "name": "my-quarkus-hello",
     "readme": "Default",
     "private": true
}'  
```
**Trick**: To delete the repository
```bash
curl -k -X 'DELETE' \
  "https://gitea.cnoe.localtest.me:8443/api/v1/repos/quarkus/my-quarkus-hello" \
  -u "$REGISTRY_USERNAME:$REGISTRY_PASSWORD" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json'
```
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
- Create a namespace for the user to be tested
```bash
kubectl create ns user1
```
- Populate the helm chart like the argocd resources at the root of the project
```bash
mvn clean package \
  -Dquarkus.helm.output-directory=$HELM_PROJECT_PATH \
  -Dquarkus.container-image.image=gitea.cnoe.localtest.me:8443/quarkus/my-quarkus-hello \
  -Dquarkus.kubernetes.namespace=user1 \
  -Dquarkus.argocd.namespace=user1 \
  -Dquarkus.argocd.project=argocd
```
- Push the Helm chart generated under the local git respository
```bash
git add .helm
git commit -asm "Push the helm chart" && git push
```
**Important**: As we are deploying the Argocd application in a namespace not managed by an `AppProject` created under `argocd` namespace, then argocd will not been able to deploy the `my-quarkus-hello` application. See the issue here: https://github.com/argoproj/argo-cd/issues/21150 and trick hereafter
```bash
echo "apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-quarkus-hello
  namespace: argocd
spec:
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  destinations:
    - namespace: '*'
      server: '*'
  sourceRepos:
    - '*'
  sourceNamespaces:
    - '*'" | kubectl apply -f -
```
- Create a secret containing the credentials to avoid to pass it within the Application `RepoUrl`
```bash
echo "apiVersion: v1
kind: Secret
metadata:
  name: private-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: https://gitea.cnoe.localtest.me:8443/quarkus/my-quarkus-hello.git
  password: $GITEA_TOKEN
  username: not-used" | k apply -f -
```

- Deploy the argocd resources
```bash
kubectl -n user1 apply -f .argocd
# kubectl -n user1 delete -f .argocd
```
- Check the Quarkus application deployed
```bash
kubectl logs -lapp.kubernetes.io/name=my-quarkus-hello -n user1
INFO exec -a "java" java -XX:MaxRAMPercentage=80.0 -XX:+UseParallelGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:+ExitOnOutOfMemoryError -Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager -cp "." -jar /deployments/quarkus-run.jar
INFO running in /deployments
__  ____  __  _____   ___  __ ____  ______
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/
2025-01-21 13:39:50,755 WARN  [io.qua.config] (main) Unrecognized configuration key "quarkus.http.host" was provided; it will be ignored; verify that the dependency extension for this configuration is set or that you did not make a typo
2025-01-21 13:39:50,888 INFO  [io.quarkus] (main) my-quarkus-hello 0.1.0 on JVM (powered by Quarkus 3.17.7) started in 0.268s.
2025-01-21 13:39:50,888 INFO  [io.quarkus] (main) Profile prod activated.
2025-01-21 13:39:50,889 INFO  [io.quarkus] (main) Installed features: [argocd, cdi, kubernetes, smallrye-context-propagation, vertx]
```

