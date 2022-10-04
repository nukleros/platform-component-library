#!/usr/bin/env sh

set -e

# DESCRIPTION: performs the overlaying a set of manifests.  this is a simply script for now, but may
#              grow over time so we will keep logic out of the Makefile
# INPUTS:
#   CATEGORY: the category of components, from the parent directory in .source (e.g. certificates, ingress)
#   PROJECT: the project, within the CATEGORY, to overlay
#
# USAGE:
#   CATEGORY=secrets PROJECT=external-secrets scripts/overlay.sh

# validate the environment
: ${CATEGORY?missing environment variable CATEGORY}
: ${PROJECT?missing environment variable PROJECT}

if [ -z `which yot` ]; then
    echo "yot not installed...please run 'make yot'..."
    exit 1
fi

CATEGORY_DIR=".source/${CATEGORY}"
PROJECT_DIR="${CATEGORY_DIR}/${PROJECT}"

# ensure category values exist
if [ ! -f ${CATEGORY_DIR}/values.yaml ]; then
    echo "missing category-specific values file at ${CATEGORY_DIR}/values.yaml..."
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
        --values-file=${CATEGORY_DIR}/values.yaml \
        --remove-comments \
        --stdout > ${CATEGORY}/${PROJECT}/${OVERLAY}
    
    # TODO: remove duplication in overlays for nukleros labels
    # run the stdout through our common overlays
    # yot \
    #    --path=- \
    #    --instructions=.source/overlay.yaml \
    #    --values-file=${PROJECT_DIR}/config/values.yaml \
    #    --values-file=${CATEGORY_DIR}/values.yaml \
    #    --remove-comments \
    #    --stdout > ${CATEGORY}/${PROJECT}/${OVERLAY}
done
