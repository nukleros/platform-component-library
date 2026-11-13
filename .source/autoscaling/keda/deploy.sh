#!/usr/bin/env sh

set -e

# DESCRIPTION: deploys the keda manifests to the cluster in the current kubectl context and waits
#              for keda to become ready.
#
# NOTE: the manifests are applied server side, as the scaledjobs crd is too large for a client
#       side apply (which stores the full object in the last-applied-configuration annotation and
#       exceeds the 256KB annotation size limit).
#
# USAGE:
#   make deploy CATEGORY=autoscaling PROJECT=keda
#   sh .source/autoscaling/keda/deploy.sh

MANIFESTS_DIR="autoscaling/keda"

# NOTE: this is not configurable, as the manifests are rendered for this namespace.
NAMESPACE="nukleros-autoscaling-system"

# create the namespace if it does not already exist
kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# apply the crds first and wait for them to be established, so that the remaining manifests
# (and anything applied immediately after this script) can rely on them
kubectl apply --server-side -f ${MANIFESTS_DIR}/crds.yaml
kubectl wait --for=condition=Established --timeout=60s -f ${MANIFESTS_DIR}/crds.yaml

kubectl apply --server-side -f ${MANIFESTS_DIR}/

# NOTE: the metrics server and admission webhooks cannot start until the operator has generated
#       the shared certificate secret, so the operator is waited on first.
kubectl -n ${NAMESPACE} rollout status deployment/keda-operator --timeout=300s
kubectl -n ${NAMESPACE} rollout status deployment/keda-operator-metrics-apiserver --timeout=300s
kubectl -n ${NAMESPACE} rollout status deployment/keda-admission-webhooks --timeout=300s

# the external metrics api is only usable once the operator has patched the ca bundle into the
# api service and the api server can reach the metrics server
kubectl wait --for=condition=Available --timeout=120s apiservice/v1beta1.external.metrics.k8s.io
