#!/usr/bin/env bash

set +x

docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 kind-registry.local:5000/hello-app:1.0
docker push kind-registry.local:5000/hello-app:1.0
kubectl create deployment hello-server --image=kind-registry.local:5000/hello-app:1.0


