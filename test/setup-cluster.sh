#!/usr/bin/env bash

export KIND_EXPERIMENTAL_PROVIDER=podman

kind delete cluster
kind create cluster --config $(pwd)/test/kind-port-80-443.cfg

kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
kubectl wait --for=condition=Ready deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready deployment/argocd-server -n argocd --timeout=120s

# See discussion: https://github.com/argoproj/argo-cd/issues/2953
kubectl patch configmap argocd-cmd-params-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

kubectl rollout restart -n argocd deployment argocd-server
kubectl apply -f $(pwd)/test/argocd-ingress.yaml

ARGOCD_ADMIN_PASSWORD=$(kubectl get secret/argocd-initial-admin-secret -n argocd -ojson | jq -r '.data.password' | base64 -d)
echo "Argocd password: $ARGOCD_ADMIN_PASSWORD"

argocd login argocd.localtest.me --grpc-web --insecure --username admin --password $ARGOCD_ADMIN_PASSWORD




