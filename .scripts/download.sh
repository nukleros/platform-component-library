#!/usr/bin/env sh

set -e

# DESCRIPTION: performs the download of a set of manifests, using vendir, from an upstream
# INPUTS:
#   CATEGORY: the category of components, from the parent directory in .source (e.g. certificates, ingress)
#   PROJECT: the project, within the CATEGORY, to download
#
# USAGE:
#   CATEGORY=secrets PROJECT=external-secrets scripts/download.sh

# validate the environment
: ${CATEGORY?missing environment variable CATEGORY}
: ${PROJECT?missing environment variable PROJECT}

if [ -z `which vendir` ]; then
    echo "vendir not installed...please run 'make vendir'..."
    exit 1
fi

if [ -z `which helm` ]; then
    echo "helm not installed..."
    exit 1
fi

PROJECT_DIR=".source/${CATEGORY}/${PROJECT}"

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

    # prefer a project-specific values-helm.yaml, otherwise fall back to the
    # chart's own default values.yaml
    if [ -f ${PROJECT_DIR}/config/values-helm.yaml ]; then
        VALUES_HELM=${PROJECT_DIR}/config/values-helm.yaml
    else
        VALUES_HELM=${PROJECT_DIR}/vendor-helm/values.yaml
    fi

    # drop documents which contain only comments (e.g. helm templates which render no
    # resources).  yot treats these as empty documents, and the common overlays inject
    # labels into them, producing label-only documents in the output.
    strip_empty_documents() {
        awk '
            /^---[ \t]*$/ { if (keep) printf "%s", doc; doc = $0 "\n"; keep = 0; next }
            { doc = doc $0 "\n"; if ($0 !~ /^[ \t]*(#.*)?$/) keep = 1 }
            END { if (keep) printf "%s", doc }
        '
    }

    # USAGE: helm_template <output file> <values file> [<values file>...]
    helm_template() {
        OUTPUT=$1
        shift

        VALUES_ARGS=""
        for VALUES in "$@"; do
            VALUES_ARGS="${VALUES_ARGS} --values ${VALUES}"
        done

        helm template ${PROJECT} ${PROJECT_DIR}/vendor-helm \
            --include-crds \
            --kube-version '1.36.1' \
            ${VALUES_ARGS} | strip_empty_documents | tee ${OUTPUT}
    }

    helm_template ${PROJECT_DIR}/vendor/${PROJECT}.yaml ${VALUES_HELM}

    # template a platform-specific variant for each values-helm-<platform>.yaml, layered
    # on top of the base values so it only needs to contain the platform overrides
    # (e.g. config/values-helm-gke.yaml produces vendor/<project>-gke.yaml)
    for VALUES_PLATFORM in ${PROJECT_DIR}/config/values-helm-*.yaml; do
        [ -f "${VALUES_PLATFORM}" ] || continue

        PLATFORM=$(basename ${VALUES_PLATFORM} .yaml)
        PLATFORM=${PLATFORM#values-helm-}

        helm_template ${PROJECT_DIR}/vendor/${PROJECT}-${PLATFORM}.yaml ${VALUES_HELM} ${VALUES_PLATFORM}
    done
fi
