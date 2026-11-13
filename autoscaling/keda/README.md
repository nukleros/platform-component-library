# Summary

For KEDA, you cannot simply run `kubectl apply -f autoscaling/keda/`.  This is because the
`scaledjobs` CRD is too large for a client-side apply, which stores the full object in the
`kubectl.kubernetes.io/last-applied-configuration` annotation and exceeds the 256KB annotation
size limit.

To install the manifests, create the namespace and use a server-side apply:

```bash
kubectl create ns nukleros-autoscaling-system --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -f autoscaling/keda/
```

> **NOTE:** the operator generates and rotates the certificates for the metrics server and
> admission webhooks itself (stored in the `kedaorg-certs` secret), so cert-manager is not
> required.  The operator restarts once on first install after writing that secret, and the
> metrics server and admission webhooks do not start until it exists.

## Deploy Script

A deploy script is available which creates the namespace, applies the manifests and waits for
KEDA to become ready.  Run it from the root of the repository:

```bash
make deploy CATEGORY=autoscaling PROJECT=keda
```

To verify the install, apply a test `ScaledObject` which scales a deployment from 0 to 2 replicas
using the cron scaler:

```bash
make test CATEGORY=autoscaling PROJECT=keda
kubectl -n nukleros-autoscaling-system get scaledobject,deployment keda-test
kubectl -n nukleros-autoscaling-system get hpa "$(kubectl -n nukleros-autoscaling-system get scaledobject keda-test -o jsonpath='{.status.hpaName}')"
```
