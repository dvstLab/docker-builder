#!/bin/bash

set -xe

DOCKER_IMAGE="rzlamrr/dvstlab"

BUILD_DATE="$(date -u +"%Y%m%d")"

# latest tag  reference(focal/lite/arch)
LATEST="focal"

TAG=("focal" "lite" "arch")

setupvar() {
    IMAGE_TAG="${1}"

    if [[ "${IMAGE_TAG}" == "focal" ]]; then
        DOCKERFILE="Focal"
    elif [[ "${IMAGE_TAG}" == "lite" ]]; then
        DOCKERFILE="Lite"
    elif [[ "${IMAGE_TAG}" == "arch" ]]; then
        DOCKERFILE="Arch"
    fi

    if [[ -z "${DOCKERFILE}" ]]; then echo "No dockerfile"; exit 1; fi

    LABELS="--label org.label-schema.build-date=${BUILD_DATE}
	--label org.label-schema.name=AIO-DvsT-builder
	--label org.label-schema.url=https://rzlamrr.github.io
	--label org.label-schema.vcs-ref=$(git rev-parse --short HEAD)
	--label org.label-schema.vcs-url=$(git remote get-url origin)
	--label org.label-schema.vendor=rizal.amrr
	--label org.label-schema.version=1.2
	--label org.label-schema.schema-version=1.0"

    FLAGS="--rm --compress --pull --file ${DOCKERFILE} --tag ${DOCKER_IMAGE}:${IMAGE_TAG}"
}

# shellcheck disable=SC2086
builder() {
    docker build . ${FLAGS} ${LABELS}
}

# shellcheck disable=SC2086
push() {
    docker push ${DOCKER_IMAGE}:${1}
}

push_latest() {
    docker tag ${DOCKER_IMAGE}:${LATEST} ${DOCKER_IMAGE}:latest
    docker push ${DOCKER_IMAGE}:latest
}

# shellcheck disable=SC2086
test() {
    docker scan --login --token ${SNYK_AUTH_TOKEN}
    docker scan --accept-license ${DOCKER_IMAGE}:${1} | tee scan/${1}.txt
}

# shellcheck disable=SC2076
if [[ -n "${1}" ]]; then
    if [[ "${1}" == "test" ]]; then
        test "${2}"
    elif [[ "${TAG[*]}" =~ "${1}" ]]; then
        setupvar "${1}"
        builder
        push "${1}"
    else
        echo "Invalid argument!"
        exit 1
    fi
else
    for i in "${TAG[@]}"; do
        setupvar "$i"
        builder
        push "$i"
        # test "$i"
    done
    push_latest
fi
