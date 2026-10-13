# Summary

For External Secrets, you cannot simply run `kubectl apply secrets/external-secrets/`.  This is because
the `secretstores` and `clustersecretstores` CRDs are too large for a client-side apply, which stores
the full object in the `kubectl.kubernetes.io/last-applied-configuration` annotation and exceeds
the 256KB annotation size limit.

To install the manifests, use a server-side apply:

```bash
kubectl apply --server-side -f secrets/external-secrets/
```
