#!/usr/bin/env bash

ARGOCD_ADMIN_PASSWORD=$(kubectl get secret/argocd-initial-admin-secret -n argocd -ojson | jq -r '.data.password' | base64 -d)
argocd login argocd.localtest.me --grpc-web --insecure --username admin --password $ARGOCD_ADMIN_PASSWORD

kubectl apply -f $(pwd)/test/test1/guestbook-app.yaml
while true; do
  STATUS=$(argocd app get argocd/guestbook -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Use case: using default AppProject"
    echo "## Succeeded: status is synced"
    kubectl get appproject/default -n argocd -oyaml
    kubectl get application/guestbook -n argocd -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done