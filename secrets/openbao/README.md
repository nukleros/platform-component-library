# Summary

For OpenBao, you cannot simply run `kubectl apply secrets/openbao/`.  This is because we 
need unseal keys prior to applying and we do not want to store encryption keys, 
even fake ones, in Git.

Prior to installing the manifests, run:

```bash
kubectl create secret generic openbao-unseal-key \
  --namespace nukleros-secrets-system \
  --from-literal=unseal-key.key=$(openssl rand -base64 32)
```
