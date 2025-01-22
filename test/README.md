## Test environment

- Create a kind cluster using the config file
```bash
kind create cluster --config kind-port-80-443.cfg 
```

- Deploy the ingress controller
```bash
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml 
```

- Install ArgoCD, expose it using ingress and patch its config to set the server as insecure
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch configmap argocd-cmd-params-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

kubectl rollout restart -n argocd deployment argocd-server  
```
- Get the argocd initial password: `kubectl get secret/argocd-initial-admin-secret -n argocd -ojson | jq -r '.data.password' | base64 -d`
- Login to the server `https://argocd.localtest.me` using as with username: `admin` and password or use the argocd CLI


