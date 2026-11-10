#!/usr/bin/env sh

set -e

# DESCRIPTION: deploys the istio manifests for a specific platform.  some manifests have
#              mutually exclusive platform variants (suffixed with the platform name), so
#              only the shared manifests plus those for the selected platform are applied.
# INPUTS:
#   PLATFORM: the platform to deploy to, one of: gke, openshift, generic
#             (may also be passed as the first argument)
#
# USAGE:
#   make deploy CATEGORY=service-mesh PROJECT=istio PLATFORM=gke
#   sh .source/service-mesh/istio/deploy.sh gke

PLATFORM=${1:-${PLATFORM}}
MANIFESTS_DIR="service-mesh/istio"

# NOTE: this is not configurable, as the manifests are rendered for this namespace.
NAMESPACE="nukleros-service-mesh-system"

case "${PLATFORM}" in
    gke)
        PLATFORM_MANIFESTS="config-gke.yaml rbac.yaml deployment-gke.yaml daemonset-gke.yaml"
        ;;
    openshift)
        PLATFORM_MANIFESTS="config-openshift.yaml rbac-openshift.yaml deployment-openshift.yaml daemonset-openshift.yaml networkattachmentdefinition-openshift.yaml"
        ;;
    generic)
        PLATFORM_MANIFESTS="config.yaml rbac.yaml deployment.yaml daemonset.yaml"
        ;;
    *)
        echo "invalid PLATFORM '${PLATFORM}'...must be one of: gke, openshift, generic"
        exit 1
        ;;
esac

# manifests which are the same on every platform
SHARED_MANIFESTS="crds.yaml service.yaml webhook.yaml horizontalpodautoscaler.yaml poddisruptionbudget.yaml networkpolicy.yaml resourcequota.yaml"

APPLY_ARGS=""
for MANIFEST in ${SHARED_MANIFESTS} ${PLATFORM_MANIFESTS}; do
    APPLY_ARGS="${APPLY_ARGS} -f ${MANIFESTS_DIR}/${MANIFEST}"
done

# create the namespace if it does not already exist
kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl apply ${APPLY_ARGS}
