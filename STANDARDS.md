# Standards

The standards every component in this repository follows.  Use this when adding or upgrading
a component (see the [developer guide](DEVELOPER.md) for the workflow).

Standards marked **where possible** are not yet applied to every component.  New components
must apply them, and existing components should be brought in line when they are upgraded.


## Directory Structure

```
.source/
  <category>/
    values.yaml                       # namespace and category for every project in the category
    <project>/
      config/
        vendor.yaml                   # vendir config, pinned to an exact upstream version
        vendor.yaml.lock              # vendir lock file (committed)
        values.yaml                   # 'project: <project>' plus any overlay variables
        values-helm.yaml              # helm values (helm charts only)
        values-helm-<platform>.yaml   # platform overrides layered on values-helm.yaml
        overlays/
          <output file>.yaml          # one yot overlay per output file, with the same name
      vendor/                         # upstream manifests, as downloaded or templated (committed)
      vendor-helm/                    # upstream helm chart (committed)
      static/                         # manifests we author which upstream does not provide
      test/                           # smoke test manifests, applied by 'make test'
      deploy.sh                       # deploy script, run by 'make deploy'
<category>/
  <project>/
    <output file>.yaml                # the opinionated manifests (the output)
    README.md                         # only when 'kubectl apply -f <category>/<project>/' won't work
```

* `vendor/` and `vendor-helm/` are committed so that upgrades show the upstream changes in Git.
* `static/`, `test/`, `deploy.sh` and the component `README.md` are only added when needed.


## Output Manifests

The output contains raw Kubernetes manifests only, one file per group of kinds:

* `ServiceAccount`, `Role`, `RoleBinding`, `ClusterRole`, `ClusterRoleBinding` == `rbac.yaml`
* `ConfigMap`, `Secret`, `ExternalSecret` == `config.yaml`
* `CustomResourceDefinition` == `crds.yaml`
* `MutatingWebhookConfiguration`, `ValidatingWebhookConfiguration`, `ValidatingAdmissionPolicy`,
  `ValidatingAdmissionPolicyBinding` == `webhook.yaml`
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
* `HorizontalPodAutoscaler` == `horizontalpodautoscaler.yaml`
* `ResourceQuota` == `resourcequota.yaml`
* `NetworkAttachmentDefinition` == `networkattachmentdefinition.yaml`
* `APIService` == `apiservice.yaml`
* Kinds not listed above use the lowercase kind name (e.g. `apiservice.yaml`), and are added to
  this list.
* Mutually exclusive variants use a suffix, pick one (e.g. `service-aws.yaml`,
  `service-nodeport.yaml`, `deployment-gke.yaml`).  A component with variants documents which
  files to apply per platform in its `README.md`, and its `deploy.sh` takes the platform as
  input.
* `Namespace` objects are not included.  The namespace is created by `deploy.sh` or the user.
* If a plain `kubectl apply -f` does not work (e.g. CRDs too large for a client-side apply,
  secrets which must be created first, variants), the component `README.md` says how to
  install it.


## Namespaces

* Each category installs into a single namespace, set in `.source/<category>/values.yaml`:
  `nukleros-<category>-system`.
* Helm charts are templated without `--namespace`, so everything upstream derives from the
  release namespace renders as `default`.  Overlays rewrite every such reference
  (`metadata.namespace`, `subjects[*].namespace`, webhook and `APIService` service
  namespaces, service addresses in container args, cluster-scoped names suffixed with the
  namespace).
* References which deliberately point at another namespace (e.g. `kube-system` role
  bindings for the API server, OpenShift's global `default` namespace) are left unchanged,
  with a `# NOTE:` saying why.


## Labels

Applied to every resource, and to the pod template of every workload:

| Label | Value |
| --- | --- |
| `platform.nukleros.io/category` | the category, e.g. `autoscaling` |
| `platform.nukleros.io/project` | the project, e.g. `keda` |

Upstream labels (`app`, `app.kubernetes.io/name`, `app.kubernetes.io/instance`,
`app.kubernetes.io/version`, `app.kubernetes.io/component`, `app.kubernetes.io/part-of`) are
kept as upstream renders them, and selectors are never modified.


## Production Readiness

### Applied everywhere

* **Pinned versions:** upstream versions are pinned exactly in `vendor.yaml`, and images use
  pinned tags (never `latest`).
* **Linux nodes:** every workload has `nodeSelector: kubernetes.io/os: linux`.
* **Anti-affinity:** every `Deployment` and `StatefulSet` prefers spreading its replicas
  across nodes (`preferredDuringSchedulingIgnoredDuringExecution`, weight 100,
  `topologyKey: kubernetes.io/hostname`, selecting its own pods).  It is preferred, not
  required, so pods still schedule on small clusters.
* **Resources:** every long-running container sets CPU and memory requests, and a memory
  limit.
* **Non-root:** containers run as non-root, except node agents which need root to do their
  job (documented with a `# NOTE:`).
* **No secrets in Git:** `Secret` manifests carry placeholder values only, with credentials
  left empty.  Secrets which must be generated (e.g. unseal keys) are documented in the
  component `README.md`.

### Applied where possible

* **No CPU limits**, to avoid CPU throttling.  Memory limits are kept.
* **At least 2 replicas** (or an `HorizontalPodAutoscaler` with `minReplicas: 2`) for
  controllers, webhooks and anything the API server calls, within what upstream's HA docs
  support.  Controllers with more than one replica use leader election.
* **Pod disruption budgets** for every workload with more than one replica:
  `minAvailable: 1` with `unhealthyPodEvictionPolicy: AlwaysAllow`, so a node drain is never
  blocked by pods which are not ready.
* **Network policies** for every workload, with both `Ingress` and `Egress` policy types:
  * Ingress is limited to the ports each component serves.  Ports called by another
    component are limited to that component's pods.
  * Ports called by the Kubernetes API server (webhooks, aggregated API servers) allow any
    source, as the API server is usually not a pod and never matches a pod or namespace
    selector.
  * Egress is either open (`- {}`) for components which must reach arbitrary destinations
    (scaler sources, cloud provider APIs, DNS providers), or limited to DNS (53, plus 5353 for
    OpenShift) and the API server (443 and 6443) on any destination.  Either way, a
    `# NOTE:` says why.
* **Zone spread:** a `topologySpreadConstraints` entry on `topology.kubernetes.io/zone` with
  `maxSkew: 1` and `whenUnsatisfiable: ScheduleAnyway` (a no-op on single zone clusters).
* **Container security context:** `allowPrivilegeEscalation: false`,
  `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]` and
  `seccompProfile.type: RuntimeDefault` (at the pod or container level).  Where upstream
  needs more (a writable root filesystem, added capabilities), it is left as upstream sets it
  with a `# NOTE:`.
* **`imagePullPolicy: IfNotPresent`** set explicitly on every container, including init
  containers, rather than relying on the Kubernetes default.  Tags are pinned, so pulling on
  every start only adds pod start time and a dependency on the registry being available.
* **Structured (JSON) logs** where upstream supports them.
* **Priority classes:** only node agents use one (`system-node-critical`), together with the
  `ResourceQuota` GKE requires to admit them outside `kube-system`.


## Other Patterns

* **Upstream source:** prefer the upstream Helm chart, since it can render PDBs, network
  policies and scheduling settings from values.  Use release manifests (vendir `http`)
  when there is no chart.  Charts are templated with `--include-crds` against a fixed
  `--kube-version`.
* **Where settings live:** for Helm charts, set everything the chart supports in
  `values-helm.yaml` and use overlays only for what it does not.  For release manifests,
  tunables (replicas, resources) are overlay variables in `config/values.yaml`, used with
  typed templates (e.g. `replicas: !!int {{ .replicas }}`).
* **Overlay structure:** each overlay file starts with the same `commonOverlays` block (labels
  and helm label removal), kept identical across files even where a query matches nothing.
  The first overlay deletes every document of a kind that does not belong in that output file.
  The second updates the namespace.  Per-workload changes are targeted with a `documentQuery`
  on `metadata.name`.
* **List merges:** yot appends when merging lists, so upstream lists (capabilities, network
  policy rules) are deleted before the replacement is merged in.
* **Comments:** every deviation from upstream, and every setting deliberately left
  unchanged, has a `# NOTE:` explaining why, in the overlay or values file that makes it.
* **Webhook certificates:** prefer upstream's own certificate generation and CA bundle
  patching.  Otherwise use cert-manager: a
  `Certificate` and `Issuer` in `certificates.yaml`, and the
  `cert-manager.io/inject-ca-from` annotation on the webhook configuration.
* **Webhook failure policy** is left as upstream sets it.
* **Services** are `ClusterIP`, except ingress controllers, which ship one variant per
  load balancer type.
* **Large CRDs** (over 256KB, the limit for the `last-applied-configuration` annotation) are
  applied with `kubectl apply --server-side`, and the component `README.md` and `deploy.sh`
  say so.
* **Deploy scripts** create the namespace and apply the right manifests (and the right variant).
  **Where possible**, they also apply the CRDs first and wait for them to be `Established`,
  then wait for every workload to roll out.
* **Smoke tests** in `test/` exercise the component end to end with no external
  dependencies.
