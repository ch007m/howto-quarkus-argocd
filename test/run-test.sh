#!/usr/bin/env bash

ARGOCD_ADMIN_PASSWORD=$(kubectl get secret/argocd-initial-admin-secret -n argocd -ojson | jq -r '.data.password' | base64 -d)
argocd login argocd.localtest.me --grpc-web --insecure --username admin --password $ARGOCD_ADMIN_PASSWORD

kubectl delete appprojects --all -A
kubectl delete applications --all -A

kubectl apply -f $(pwd)/test/test1/01_default-project.yaml
sleep 10
kubectl apply -f $(pwd)/test/test1/02_guestbook-app.yaml
while true; do
  STATUS=$(argocd app get argocd/guestbook-test1 -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test1"
    echo "Use default AppProject of argocd namespace (full rights)"
    echo "Application created under argod namespace"
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

kubectl apply -f $(pwd)/test/test2/01_guestbook-project.yaml
sleep 10
kubectl apply -f $(pwd)/test/test2/02_guestbook-app.yaml
while true; do
  STATUS=$(argocd app get argocd/guestbook-test2 -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test2"
    echo "## Use \"guestbook\" AppProject deployed under namespace: argocd"
    echo "## & Application in argocd namespace too"
    echo "## Succeeded: status is synced"
    kubectl get appproject/guestbook-test2 -n argocd -oyaml
    kubectl get application/guestbook-test2 -n argocd -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done

kubectl apply -f $(pwd)/test/test3/01_guestbook-project.yaml
sleep 10
kubectl apply -f $(pwd)/test/test3/02_guestbook-app.yaml
while true; do
  STATUS=$(argocd app get test3/guestbook-test3 -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test3"
    echo "Use guestbook AppProject deployed under argocd namespace"
    echo "& Application created under the namespace: test3"
    echo "## Succeeded: status is synced"
    kubectl get appproject/guestbook -n argocd -oyaml
    kubectl get application/guestbook-test3 -n test3 -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done