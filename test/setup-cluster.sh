#!/usr/bin/env bash

export KIND_EXPERIMENTAL_PROVIDER=podman

kind delete cluster
kind create cluster --config $(pwd)/test/kind-port-80-443.cfg

kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
kubectl wait --for=condition=Ready deployment/ingress-nginx-controller -n ingress-nginx --timeout=90s

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready deployment/argocd-server -n argocd --timeout=90s

# See discussion about why we got HTTP 30x error and workaround
# https://github.com/argoproj/argo-cd/issues/2953
kubectl patch configmap argocd-cmd-params-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true","application.namespaces":"test3"}}'

kubectl rollout restart -n argocd deployment argocd-server
kubectl rollout restart -n argocd statefulset argocd-application-controller

kubectl apply -f $(pwd)/test/argocd-ingress.yaml

echo "## Cluster created and ready"




