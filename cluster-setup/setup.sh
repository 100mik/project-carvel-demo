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


# TODO: clean up
reg_name='kind-registry.local'
reg_port='5000'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi


if ! kind get clusters | grep "$CLUSTER_NAME"; then
  echo "~~ Setting up kind cluster"
  kind create cluster --config "$SCRIPT_DIR/kind.yml" --name "$CLUSTER_NAME"
  echo "~~ Setting up kind cluster > done"
  echo "~~ Creating namespace for Packaging APIs"
  kubectl create ns installs
  echo "~~ Creating namespace for Packaging APIs > done"
fi

# TODO: cleanup
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes --name ${CLUSTER_NAME}); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# TODO: add documentation?


echo "~~ Setting nginx ingress"
if kapp inspect --app nginx-ingress >/dev/null; then
  echo "~~ Setting nginx ingress > already installed, skipping"
else
  vendir sync --locked --file "$SCRIPT_DIR/vendir.yml" --lock-file "$SCRIPT_DIR/vendir.lock.yml"
  kapp deploy --app nginx-ingress --file "$SCRIPT_DIR/nginx-ingress/deploy/static/provider/kind/deploy.yaml" --yes
  echo "~~ Setting nginx ingress > done"
fi

echo "~~ Setting kapp-controller"
if kapp inspect --app kapp-controller >/dev/null; then
  echo "~~ Setting kapp controller > already installed, skipping"
else
  vendir sync --locked --file "$SCRIPT_DIR/vendir.yml" --lock-file "$SCRIPT_DIR/vendir.lock.yml"
  kapp deploy --app kapp-controller --file "$SCRIPT_DIR/kapp-controller/release.yml" --file "$SCRIPT_DIR/kapp-controller-sa.yml" --yes
  echo "~~ Setting kapp controller > done"
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


# TODO

kapp deploy --app demo-package \
  --namespace default \
  --file "$SCRIPT_DIR/install-ns.yml" \
  --file "$SCRIPT_DIR/../packaging-apis/repository/packages/carvel.garnier.wf/" \
  --yes
