# Platform Component Library

Common components that provide supporting services to tenant workloads on a
Kubernetes application platform.

This is a repository of different open source platform components that are
aggregated and modified with some best practices that we have found useful.
You can use these manifests to install the various platform supporting services
as-is, or more likely, you can use them as a starting point for developing:
* [Helm](https://github.com/helm/helm) charts
* [Kustomize](https://github.com/kubernetes-sigs/kustomize) overlays
* Kubernetes operators using [Operator
  Builder](https://github.com/nukleros/operator-builder)

We use [vendir](https://github.com/vmware-tanzu/carvel-vendir) to sync upstream
source manifests from different projects.

We use
[yaml-overlay-tool](https://github.com/vmware-tanzu-labs/yaml-overlay-tool) to
encode changes that we find useful to the source manifests.

This allows us to readily keep the component configs up-to-date with latest
versions.

## Version Upgrade

Following is an example of upgrading the cert-manager manifests.

First, update the version number in the URL for the cert-manager manifest in
`.source/certificates/cert-manager/config/vendor.yaml`.

Then you can sync the latest manifests as follows.

```bash
export GROUP=certificates
export PROJECT=cert-manager
make download
```

Next, apply the overlays.

```bash
make overlay
```

Now the manifests in the `certificates/cert-manager` directory will be updated
to the latest version specified in `.source/certificates/cert-manager/config/vendor.yaml`.

