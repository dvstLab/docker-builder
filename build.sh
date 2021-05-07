#!/bin/bash

set -xe

DOCKER_IMAGE="rzlamrr/dvstlab"

BUILD_DATE="$(date -u +"%Y%m%d")"

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

install_scanner() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    DEBIAN_FRONTEND=noninteractive sudo apt install -qqy docker-scan-plugin
    DOCKER_SCAN_INSTALLED=yes
    export DOCKER_SCAN_INSTALLED
}

test() {
    docker scan --accept-license --json ${DOCKER_IMAGE}:${1} | tee scan/${1}.json
    docker scan --accept-license ${DOCKER_IMAGE}:${1} | tee scan/${1}.txt
}

## Install Docker Scan PLugin ##
if [[ "${DOCKER_SCAN_INSTALLED}" != "yes" ]]; then
    install_scanner
fi

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
