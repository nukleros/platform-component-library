---
name: add-component
description: Add a new platform component (or upgrade an existing one) to this repo end to end - vendir download, yot overlays into the opinionated output format defined in STANDARDS.md (structure, naming, labels, production readiness), a deploy script, and verification on a local kind cluster. Use when asked to add, implement, or onboard a new component/project, e.g. "add KEDA as autoscaling/keda".
argument-hint: CATEGORY=<category> PROJECT=<project> <upstream install docs URL>
---

# Add a platform component

Inputs: `CATEGORY`, `PROJECT`, and the upstream install docs URL (and version). If any are
missing, ask.

**Read [STANDARDS.md](../../../STANDARDS.md) first.** It is the source of truth for the
directory structure, output file naming, namespaces, labels, production readiness controls
and overlay patterns. The output must meet every standard in it, including the ones marked
"where possible" (those are only inconsistent in older components). Any deviation needs a
`# NOTE:` explaining why, and must be called out in the final summary.
[DEVELOPER.md](../../../DEVELOPER.md) has the `make` workflow. This skill adds the steps,
techniques and checks around them.

## 1. Research upstream

- Read the upstream install docs for the requested version. Note: install methods (Helm
  chart vs. release YAML), supported Kubernetes versions, the HA guidance (how many replicas
  each component supports, leader election, active/passive), the ports each component
  listens on and who calls them, and how certificates are managed. These drive the replica,
  network policy and certificate decisions in STANDARDS.md.
- Pull the chart into the scratchpad (`helm pull <repo>/<chart> --version X --untar`) and
  read `values.yaml` and the templates before writing values. Note which standards the chart
  can satisfy from values (PDBs, network policies, affinity, spread, resources) and which
  need overlays.

## 2. Scaffold and download

```bash
make project CATEGORY=<category> PROJECT=<project>
```

- New category: confirm `.source/<category>/values.yaml` has the right namespace (see
  Namespaces in STANDARDS.md).
- Remove `static/` if it is unused.
- Write `config/vendor.yaml` following an existing one (Helm:
  `.source/autoscaling/keda/config/vendor.yaml`; HTTP:
  `.source/certificates/cert-manager/config/vendor.yaml`).
- Write `config/values.yaml` and, for Helm, `config/values-helm.yaml`. Only include values
  that differ from the chart defaults, each with a `# NOTE:`.

```bash
make download CATEGORY=<category> PROJECT=<project>
grep '^kind:' .source/<category>/<project>/vendor/<project>.yaml | sort | uniq -c
```

## 3. Apply the standards

Work through the Production Readiness section of STANDARDS.md for every workload. The
techniques that aren't obvious:

- **Removing a chart default** (e.g. the CPU limit): Helm deep-merges values, so set the key
  to `null` (`limits: {cpu: null, memory: ...}`). Leaving the key out keeps the default.
  Check the rendered output.
- **Settings the chart doesn't expose** (e.g. `unhealthyPodEvictionPolicy`): add them with a
  `merge` overlay on `spec`.
- **Replacing upstream network policy rules**: delete `spec.ingress`/`spec.egress`, then
  merge the replacement in, targeted per policy with a `documentQuery` on `metadata.name`.
- **Chart network policies usually need replacing**: most only allow pod or namespace
  selectors on the webhook and aggregated-API ports, which the API server never matches.

## 4. Overlays

Copy the shape of `.source/autoscaling/keda/config/overlays/` (or
`.source/service-mesh/istio/config/overlays/` for platform variants). Create one overlay per
output file, named as in STANDARDS.md. If a new kind isn't listed there, add it.

Find every reference to the release namespace, which renders as `default`:

```bash
awk '/^kind: CustomResourceDefinition/{f=1} /^---/{f=0} !f' .source/<category>/<project>/vendor/<project>.yaml | grep -n -E 'default|\.svc'
```

When upstream also has intentional `kube-system` references, only rewrite the ones that say
`default`:

```yaml
- name: "ensure namespace is updated"
  query: metadata.namespace
  value: "{{ .namespace }}"
  documentQuery:
    - conditions:
        - query: $[?($.metadata.namespace == "default")]

- name: "ensure subject namespace is updated"
  query: subjects[?(@.namespace == "default")].namespace
  value: "{{ .namespace }}"
```

Container args are rewritten with a filter on the arg prefix, e.g.
`spec.template.spec.containers[?(@.name == "x")].args[?(@ =~ /^--some-address=/)]`.

```bash
make overlay CATEGORY=<category> PROJECT=<project>
```

Check the output against STANDARDS.md:
- no `namespace: default`, and the intentional cross-namespace references are intact
- the nukleros labels are on every resource and pod template, and no helm labels remain
- the production readiness controls are present

## 5. Deploy script, tests and README

- Create `.source/<category>/<project>/deploy.sh` (mode 644, run via `make deploy`). Use
  `.source/autoscaling/keda/deploy.sh` as the template for a single variant, or
  `.source/service-mesh/istio/deploy.sh` for platform variants.
- Check CRD sizes. Anything over 256KB needs `--server-side`:
  ```bash
  awk '/^  name: /{name=$2} /^---/{if(size)print size, name; size=0} {size+=length($0)+1} END{print size, name}' <category>/<project>/crds.yaml
  ```
- Add `.source/<category>/<project>/test/*.yaml`: a minimal end-to-end smoke test with no
  external dependencies. `make test` applies it into the namespace.
- Add `<category>/<project>/README.md` only when STANDARDS.md calls for one. Keep it short,
  like the existing ones.

## 6. Verify on kind

Use a scratchpad kubeconfig so the user's kubeconfig and current context are untouched. Use
a multi-node cluster so anti-affinity and PDBs are exercised:

```bash
cat > $SCRATCH/kind.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF
kind create cluster --name <project>-test --config $SCRATCH/kind.yaml --kubeconfig $SCRATCH/kubeconfig --wait 120s
export KUBECONFIG=$SCRATCH/kubeconfig
make deploy CATEGORY=<category> PROJECT=<project>
make test CATEGORY=<category> PROJECT=<project>
```

Check each of these, and report the result:

1. The Kubernetes version is within upstream's supported range.
2. Pods are Ready and spread across workers, and PDBs show allowed disruptions >= 1.
3. Logs have no recurring errors. Explain any restarts or startup-only errors (e.g. one
   restart after self-generated certs are written).
4. The smoke test works end to end.
5. Webhooks are actually reached: submit something the webhook must reject. Webhooks with
   `failurePolicy: Ignore` fail open silently, so a blocked webhook otherwise looks healthy.
6. Network policies are enforced (kindnet enforces them). From a throwaway pod in another
   namespace, run `nc -z` against a port that should be blocked and one that should be open.
7. Drain the node running the leader, or a replica of each component. The drain should
   complete, leadership should fail over, and the component should keep serving. Uncordon
   the node afterwards.
8. Re-running `make download` and `make overlay` produces byte-identical output (compare
   `shasum` before and after).

When done, delete the cluster: `kind delete cluster --name <project>-test --kubeconfig ...`.

## 7. Wrap up

- Don't commit unless asked.
- Summarize: files added, which STANDARDS.md controls were applied, every deviation (with
  the reason), test results, and anything untested (e.g. other platforms).
- If the component established a new pattern, or a new kind for the naming list, update
  STANDARDS.md as part of the change.
