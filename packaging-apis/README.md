# Packaging apis

Not intended to be shown during the demo


## Show package repository

## Releasing a new version

Package:

```
cd package/
kctrl package release --repo-output ../repository --version 1.0.0
```

Repo:

```
cd repository/
kctrl package repository release -v 1.0.0
```

Add to the cluster (already in cluster-setup/setup.sh):

```
kubectl create namespace installs || true

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
```

