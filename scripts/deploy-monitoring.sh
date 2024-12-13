#!/bin/bash
set -e

# Deploy Application
kubectl apply -f ./k8s/kubernetes-manifests.yaml

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all --timeout=600s

# Confirm the cluster is functional by connecting to it
gcloud container clusters get-credentials online-boutique --region=us-central1-a --project=i-hexagon-438514-g4
