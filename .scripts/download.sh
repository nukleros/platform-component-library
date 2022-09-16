#!/usr/bin/env sh

set -e

# DESCRIPTION: performs the download of a set of manifests, using vendir, from an upstream
# INPUTS:
#   GROUP:   the group classification, from the parent directory in .source (e.g. certificates, ingress)
#   PROJECT: the project, within the GROUP, to download
#
# USAGE:
#   GROUP=secrets PROJECT=external-secrets scripts/download.sh

# validate the environment
: ${GROUP?missing environment variable GROUP}
: ${PROJECT?missing environment variable PROJECT}

if [ -z `which vendir` ]; then
    echo "vendir not installed...please run 'make vendir'..."
    exit 1
fi

PROJECT_DIR=".source/${GROUP}/${PROJECT}"

# sync the project
# NOTE: this is meant to be run from a make target and will not work
#       if run from other locations.
vendir sync \
    --file ${PROJECT_DIR}/config/vendor.yaml \
    --lock-file ${PROJECT_DIR}/config/vendor.yaml.lock

# if we produced a vendor-helm directory in the project, we must template it
if [ -d ${PROJECT_DIR}/vendor-helm ]; then
    # ensure the vendir directory exists
    mkdir -p ${PROJECT_DIR}/vendor

    # ensure the vendir directory is clean
    rm -rf ${PROJECT_DIR}/vendor/*

    helm template ${PROJECT} ${PROJECT_DIR}/vendor-helm --include-crds | tee ${PROJECT_DIR}/vendor/${PROJECT}.yaml
fi
