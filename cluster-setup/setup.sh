#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME=carvel


if ! type kind 2>/dev/null; then
  echo -e "
!! kind is not installed, please install kind

See: https://kind.sigs.k8s.io/docs/user/quick-start/#installation

On macOS:

  brew install kind
"
  exit 1
fi

if ! type kapp 2>/dev/null; then
  echo -e "
!! kapp is not installed, please install kapp

See: https://carvel.dev/kapp/docs/v0.57.0/install/

On macOS:

  brew tap vmware-tanzu/carvel && brew install kapp
"
  exit 1
fi

if ! type vendir 2>/dev/null; then
  echo -e "
!! vendir is not installed, please install vendir

See: https://carvel.dev/vendir/docs/v0.34.x/install/

On macOS:

  brew tap vmware-tanzu/carvel && brew install vendir
"
  exit 1
fi


###########################################
# 🏗️ Registry + Cluster
###########################################
reg_name='kind-registry.local'
reg_port='5000'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  echo "~~ Setting up local registry"
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
  echo "~~ Setting up local registry > done"
fi

if ! kind get clusters | grep "$CLUSTER_NAME"; then
  echo "~~ Setting up kind cluster"
  kind create cluster --config "$SCRIPT_DIR/kind.yml" --name "$CLUSTER_NAME"
  echo "~~ Setting up kind cluster > done"
fi

REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes --name ${CLUSTER_NAME}); do
  echo "~~ Configuring kind node [${node}] to use local registry"
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
  echo "~~ Configuring kind node [${node}] to use local registry > done"
done

if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  echo "~~ Connecting local registry to [kind] network"
  docker network connect "kind" "${reg_name}"
  echo "~~ Connecting local registry to [kind] network > done"
fi


###########################################
# ⏩️ nginx ingress + coredns
###########################################
echo "~~ Setting nginx ingress"
if kapp inspect --app nginx-ingress >/dev/null; then
  echo "~~ Setting nginx ingress > already installed, skipping"
else
  vendir sync --locked --file "$SCRIPT_DIR/vendir.yml" --lock-file "$SCRIPT_DIR/vendir.lock.yml"
  kapp deploy --app nginx-ingress --file "$SCRIPT_DIR/nginx-ingress/deploy/static/provider/kind/deploy.yaml" --yes
  echo "~~ Setting nginx ingress > done"
fi

echo "~~ Configuring CoreDNS for 127.0.0.1.nip.io"
kubectl get configmap coredns \
  --namespace kube-system \
  --output yaml |
    ytt \
      --file - \
      --file "$SCRIPT_DIR/coredns-overlay.yml" |
    kubectl apply --filename -
echo "~~ Configuring CoreDNS for 127.0.0.1.nip.io > done"


###########################################
# 🛂️ kapp-controller
###########################################
echo "~~ Setting kapp-controller"
if kapp inspect --app kapp-controller >/dev/null; then
  echo "~~ Setting kapp controller > already installed, skipping"
else
  vendir sync --locked --file "$SCRIPT_DIR/vendir.yml" --lock-file "$SCRIPT_DIR/vendir.lock.yml"
  kapp deploy --app kapp-controller --file "$SCRIPT_DIR/kapp-controller/release.yml" --file "$SCRIPT_DIR/kapp-controller-sa.yml" --yes
  echo "~~ Setting kapp controller > done"
fi


###########################################
# 📦️ install package repository
###########################################
kubectl apply -f "$SCRIPT_DIR/install-ns.yml"

echo "~~ Relocating package repository to local registry"
if imgpkg tag resolve -i kind-registry.local:5000/demo/carvel-package-repository:1.0.0 2>/dev/null; then
  echo "~~ Relocating package repository to local registry > already present, skipping"
else
  imgpkg copy --bundle dgarnier963/carvel-package-repository:1.0.0 \
    --to-repo kind-registry.local:5000/demo/carvel-package-repository
  echo "~~ Relocating package repository to local registry > done"
fi

echo "~~ Installing package repository"
if kctrl package repo list -n installs | grep -q "Reconcile succeeded"; then
  echo "~~ Installing package repository > already installed, skipping"
else
  kctrl package repo add --repository carvel-demo \
    --url kind-registry.local:5000/demo/carvel-package-repository:1.0.0 -n installs
  echo "~~ Installing package repository > done"
fi
