#!/bin/bash


kubectl label ns default istio-injection=enabled --context kind-cluster1
kubectl label ns default istio-injection=enabled --context kind-cluster2
kubectl run nginx --image nginx:alpine --port 80 --context kind-cluster1
kubectl run nginx --image nginx:alpine --port 80 --context kind-cluster2
kubectl expose pod/nginx --context kind-cluster1
kubectl expose pod/nginx --context kind-cluster2 
