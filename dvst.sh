#!/bin/bash
export PATH=~/bin:/usr/local/bin:/home/dvst/bin:$PATH
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_COMPRESSLEVEL=8
export CCACHE_DIR=/srv/ccache

# Custom
sign() {
    java -jar "$HOME"/zipsigner-3.0.jar "$@"
}

gitconf() {
    git config --global user.email "rzlamrr.dvst@protonmail.com"
    git config --global user.name "rzlamrr"
    git config --global core.editor "nano"
    git config --global color.ui true
}

# shellcheck disable=SC2145
regen() {
    rm -rf out mklog.txt
    make O=out ARCH=arm64 "$@"
    cp out/.config arch/arm64/configs/"$@"
}
