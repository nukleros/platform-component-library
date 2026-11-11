# Summary

For Istio, you cannot simply run `kubectl apply -f service-mesh/istio/`.  This is because the
directory contains platform-specific variants of some manifests (suffixed with the platform name),
and applying all of them would apply conflicting versions of the same resources.

Apply the shared manifests, plus either the generic or the platform-specific version of the rest:

| Manifest | Generic (EKS, AKS, kind, etc.) | GKE | OpenShift |
|---|---|---|---|
| `crds.yaml`, `service.yaml`, `webhook.yaml`, `horizontalpodautoscaler.yaml`, `poddisruptionbudget.yaml`, `networkpolicy.yaml`, `resourcequota.yaml` | yes | yes | yes |
| `config` | `config.yaml` | `config-gke.yaml` | `config-openshift.yaml` |
| `daemonset` | `daemonset.yaml` | `daemonset-gke.yaml` | `daemonset-openshift.yaml` |
| `deployment` | `deployment.yaml` | `deployment-gke.yaml` | `deployment-openshift.yaml` |
| `rbac` | `rbac.yaml` | `rbac.yaml` | `rbac-openshift.yaml` |
| additional | | | `networkattachmentdefinition-openshift.yaml` |

## Deploy Script

A deploy script is available which creates the namespace and applies the correct manifests for a
platform (one of `gke`, `openshift`, `generic`).  Run it from the root of the repository:

```bash
make deploy CATEGORY=service-mesh PROJECT=istio PLATFORM=gke
```

## Manual Install

Create the namespace first, then apply the manifests for your platform.

### GKE

```bash
kubectl create ns nukleros-service-mesh-system --dry-run=client -o yaml | kubectl apply -f -

cd service-mesh/istio
kubectl apply \
  -f crds.yaml -f config-gke.yaml -f rbac.yaml -f service.yaml -f webhook.yaml \
  -f deployment-gke.yaml -f horizontalpodautoscaler.yaml -f poddisruptionbudget.yaml \
  -f daemonset-gke.yaml -f networkpolicy.yaml -f resourcequota.yaml
```

### OpenShift

```bash
kubectl create ns nukleros-service-mesh-system --dry-run=client -o yaml | kubectl apply -f -

cd service-mesh/istio
kubectl apply \
  -f crds.yaml -f config-openshift.yaml -f rbac-openshift.yaml -f service.yaml -f webhook.yaml \
  -f deployment-openshift.yaml -f horizontalpodautoscaler.yaml -f poddisruptionbudget.yaml \
  -f daemonset-openshift.yaml -f networkpolicy.yaml -f resourcequota.yaml \
  -f networkattachmentdefinition-openshift.yaml
```

### Generic (EKS, AKS, kind, etc.)

```bash
kubectl create ns nukleros-service-mesh-system --dry-run=client -o yaml | kubectl apply -f -

cd service-mesh/istio
kubectl apply \
  -f crds.yaml -f config.yaml -f rbac.yaml -f service.yaml -f webhook.yaml \
  -f deployment.yaml -f horizontalpodautoscaler.yaml -f poddisruptionbudget.yaml \
  -f daemonset.yaml -f networkpolicy.yaml -f resourcequota.yaml
```
