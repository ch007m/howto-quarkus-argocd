#!/usr/bin/env bash

ARGOCD_ADMIN_PASSWORD=$(kubectl get secret/argocd-initial-admin-secret -n argocd -ojson | jq -r '.data.password' | base64 -d)
argocd login argocd.localtest.me --grpc-web --insecure --username admin --password $ARGOCD_ADMIN_PASSWORD

kubectl delete appprojects --all -A
kubectl delete applications --all -A

kubectl create ns test1
kubectl apply -f $(pwd)/test/test1
while true; do
  STATUS=$(argocd app get argocd/guestbook-test1 -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test1: using default AppProject"
    echo "## Succeeded: status is synced"
    kubectl get appproject/default -n argocd -oyaml
    kubectl get application/guestbook-test1 -n argocd -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done

kubectl create ns test2
kubectl apply -f $(pwd)/test/test2
while true; do
  STATUS=$(argocd app get argocd/guestbook-test2 -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test2: using guestbook AppProject"
    echo "## Succeeded: status is synced"
    kubectl get appproject/guestbook -n argocd -oyaml
    kubectl get application/guestbook-test2 -n argocd -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done