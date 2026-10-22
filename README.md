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


## Tools

* [vendir](https://github.com/vmware-tanzu/carvel-vendir) - download different formats from upstream
* [yaml-overlay-tool](https://github.com/vmware-tanzu-labs/yaml-overlay-tool) - overlay opinions from downloaded manifests


## Purpose

* **Opinionated Manifests** - provide opinions about what a real world deployment
looks like for common projects.

* **Common Format** - no guessing about whether to use Helm, Kustomize, Git, HTTP,
OCI, etc.  Everything in this repo is output in raw Kubernetes manifests.  In 
most cases, you can `kubectl apply` directly.

* **Updates** - an opinionated pipeline makes updating versions both trackable via 
Git (e.g. see what changed), and easy to perform with the used tooling.

* **Consistent Structure** - consistent naming for the output manifests:
    * `ServiceAccount`, `Role`, `RoleBinding`, `ClusterRole`, `ClusterRoleBinding` == `rbac.yaml`
    * `ConfigMap`, `Secret`, `ExternalSecret` == `config.yaml`
    * `CustomResourceDefinition` == `crds.yaml`
    * `MutatingWebhookConfiguration`, `ValidatingWebhookConfiguration` == `webhook.yaml`
    * `Certificate`, `Issuer`, `ClusterIssuer` == `certificates.yaml`
    * `Deployment` == `deployment.yaml`
    * `StatefulSet` == `statefulset.yaml`
    * `DaemonSet` == `daemonset.yaml`
    * `Job`, `CronJob` == `job.yaml`
    * `Service` == `service.yaml`
    * `Ingress`  == `ingress.yaml`
    * `IngressClass` == `ingress-class.yaml`
    * `NetworkPolicy` == `networkpolicy.yaml`
    * `PodDisruptionBudget` == `poddisruptionbudget.yaml`
    * Mutually exclusive variants use a suffix, pick one (e.g. `service-aws.yaml`,
      `service-nodeport.yaml`)


## Supported Projects

See [.source/$CATEGORY](.source/) for a list of supported projects where `$CATEGORY` is the 
category of the project.

See the [developer guide](DEVELOPER.md) to add projects or upgrade existing ones.
