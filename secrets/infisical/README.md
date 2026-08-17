# Summary

For Infisical, you cannot simply run `kubectl apply secrets/infisical/`.  This is because we 
need encryption keys prior to applying and we do not want to store encryption keys, 
even fake ones, in Git.

Prior to installing the manifests, run:

```bash
kubectl create secret generic infisical-secrets \
  --namespace nukleros-secrets-system \
  --from-literal=AUTH_SECRET="$(openssl rand -base64 32)" \
  --from-literal=ENCRYPTION_KEY="$(openssl rand -hex 16)" \
  --from-literal=SITE_URL="http://localhost"
```