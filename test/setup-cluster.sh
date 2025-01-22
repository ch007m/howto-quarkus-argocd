#!/usr/bin/env bash

retry() {
    for _ in {1..3}; do
        local ret=0
        $1 || ret="$?"
        if [[ "$ret" -eq 0 ]]; then
            return 0
        fi
        sleep 3
    done

    echo "$1": "$2."
    return "$ret"
}

export KIND_EXPERIMENTAL_PROVIDER=podman

kind delete cluster
kind create cluster --config $(pwd)/test/kind-port-80-443.cfg

kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
retry kubectl wait --for=condition=Ready deployment/ingress-nginx-controller -n ingress-nginx --timeout=30s

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
retry kubectl wait --for=condition=Ready deployment/argocd-server -n argocd --timeout=30s

# See discussion: https://github.com/argoproj/argo-cd/issues/2953
kubectl patch configmap argocd-cmd-params-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true","application.namespaces":"test3"}}'

kubectl rollout restart -n argocd deployment argocd-server
kubectl apply -f $(pwd)/test/argocd-ingress.yaml

echo "## Cluster created and ready"




