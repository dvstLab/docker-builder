#!/bin/bash

set -xe

DOCKER_IMAGE="rzlamrr/dvstlab"

BUILD_DATE="$(date -u +"%Y%m%d")"

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

    FLAGS="--rm --force-rm --compress --no-cache=true --pull
	--file ${DOCKERFILE}
	--tag ${DOCKER_IMAGE}:${IMAGE_TAG}"
}

builder() {
    docker build . ${FLAGS} ${LABELS}
}

push() {
    docker push ${DOCKER_IMAGE}:${1}
}

test() {
    docker pull ${DOCKER_IMAGE}:${1}
    docker run --rm -i --name docker_${1} --hostname ${1} -c 64 -m 256m \
        ${DOCKER_IMAGE}:${1} bash -c 'cat /etc/os-release'
}

TAG=("focal" "lite" "arch")

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
        test "$i"
    done
fi
