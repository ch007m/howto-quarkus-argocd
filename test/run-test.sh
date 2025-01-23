#!/usr/bin/env bash

kubectl delete appprojects --all -A
kubectl delete applications --all -A

kubectl create ns test1
kubectl apply -f $(pwd)/test/test1/01_default-project.yaml
sleep 10
kubectl apply -f $(pwd)/test/test1/02_guestbook-app.yaml
while true; do
  STATUS=$(kubectl get application/guestbook-test1 -n argocd -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test1"
    echo "## Use \"default\" AppProject of argocd control plane's namespace."
    echo "## Application deployed under argocd control plane's namespace."
    echo "##"
    echo "## Succeeded: status is synced"
    echo "##"
    kubectl get appproject/default -n argocd -oyaml
    echo "##"    
    kubectl get application/guestbook-test1 -n argocd -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done

kubectl create ns test2
kubectl apply -f $(pwd)/test/test2/01_guestbook-project.yaml
sleep 10
kubectl apply -f $(pwd)/test/test2/02_guestbook-app.yaml
while true; do
  STATUS=$(kubectl get application/guestbook-test2 -n argocd -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test2"
    echo "## Use \"guestbook\" AppProject deployed under argocd control plane's namespace: argocd."
    echo "## Application deployed under argocd control plane's namespace"
    echo "##"    
    echo "## Succeeded: status is synced"
    echo "##" 
    kubectl get appproject/guestbook-test2 -n argocd -oyaml
    echo "##" 
    kubectl get application/guestbook-test2 -n argocd -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done

kubectl create ns test3
kubectl apply -f $(pwd)/test/test3/01_guestbook-project.yaml
sleep 10
kubectl apply -f $(pwd)/test/test3/02_guestbook-app.yaml
while true; do
  STATUS=$(kubectl get application/guestbook-test3 -n test3 -o json | jq -r '.status.sync.status' | tr -d '\n')

  if [[ "$STATUS" == "Synced" ]]; then
    echo "## Test3"
    echo "## Use \"guestbook\" AppProject deployed under argocd control plane's namespace: argocd."
    echo "## Application deployed under a user's namespace: test3"
    echo "##"
    echo "## Succeeded: status is synced"
    echo "##"
    kubectl get appproject/guestbook -n argocd -oyaml
    echo "##"
    kubectl get application/guestbook-test3 -n test3 -oyaml
    break
  else
    echo "Current status: $STATUS"
    echo "## Wait ..."
    sleep 10
  fi
done