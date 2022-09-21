#!/usr/bin/env sh

set -e

# DESCRIPTION: performs the overlaying a set of manifests.  this is a simply script for now, but may
#              grow over time so we will keep logic out of the Makefile
# INPUTS:
#   GROUP:   the group classification, from the parent directory in .source (e.g. certificates, ingress)
#   PROJECT: the project, within the GROUP, to overlay
#
# USAGE:
#   GROUP=secrets PROJECT=external-secrets scripts/overlay.sh

# validate the environment
: ${GROUP?missing environment variable GROUP}
: ${PROJECT?missing environment variable PROJECT}

if [ -z `which yot` ]; then
    echo "yot not installed...please run 'make yot'..."
    exit 1
fi

GROUP_DIR=".source/${GROUP}"
PROJECT_DIR="${GROUP_DIR}/${PROJECT}"

# ensure group values exist
if [ ! -f ${GROUP_DIR}/values.yaml ]; then
    echo "missing group-specific values file at ${GROUP_DIR}/values.yaml..."
    exit 1
fi

# ensure project values exist
if [ ! -f ${PROJECT_DIR}/config/values.yaml ]; then
    echo "missing project-specific values file at ${PROJECT_DIR}/config/values.yaml..."
    exit 1
fi

for OVERLAY in `ls ${PROJECT_DIR}/config/overlays`; do \
    yot \
        --indent-level=2 \
        --instructions=${PROJECT_DIR}/config/overlays/${OVERLAY} \
        --output-directory=. \
        --values-file=${PROJECT_DIR}/config/values.yaml \
        --values-file=${GROUP_DIR}/values.yaml \
        --remove-comments \
        --stdout > ${GROUP}/${PROJECT}/${OVERLAY}
    
    # TODO: remove duplication in overlays for nukleros labels
    # run the stdout through our common overlays
    # yot \
    #    --path=- \
    #    --instructions=.source/overlay.yaml \
    #    --values-file=${PROJECT_DIR}/config/values.yaml \
    #    --values-file=${GROUP_DIR}/values.yaml \
    #    --remove-comments \
    #    --stdout > ${GROUP}/${PROJECT}/${OVERLAY}
done
