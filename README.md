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

## Purpose

The primary purpose for this project is to maintain manifests that are used in
other projects as a basis for installing platform components.  This project helps
keep component manifests up-to-date with upstream sources so that downstream
projects can extend them as needed.

Secondarily, the manifests in this repo can be used as-is for testing and
development environments.

As such, the manifests in this project are not intended to provide configuration
optionality for different use-cases and applications.  The only optionalities
available in this repo are for different infra providers.

## Supported Projects

Following are the currently supported groups and projects.

* certificates
    * Cert Manager
* ingress
    * External DNS
    * Kong Ingress Controller
    * Nginx Ingress Controller

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

## Add New Project

To add a new project, first add the necessary sub-directories and files in the
`.source` directory.

```bash
export GROUP=<new or existing group>
export PROJECT=<some project>
make project
```

For projects with static manifests available, we use vendir to fetch manifests.
Edit the `.source/<group>/<project>/config/vendor.yaml` and configure
vendir to fetch the upstream manifests and deposit them into the
`.source/<group>/<project>/vendor` directory.  See other examples in this repo
and refer to [vendir docs](https://carvel.dev/vendir/docs/v0.30.0/) for details.
Download the upstream manifests.

TODO: add instructions for projects with helm chart only.

```bash
make download
```

Next, create the overlay instructions to generate the final manifests.  Refer to
other examples in this project and the [yaml-overlay-tool
docs](https://docs.yaml-overlay-tool.io/).  Overlay the upstream manifests with
yot to produce the final static manifests.

```bash
make overlay
```

