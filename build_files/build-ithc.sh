#!/bin/bash

set -ouex pipefail

# https://github.com/quo/ithc-linux - the same driver linux-surface carries in its kernel patches
ITHC_REPO="https://github.com/quo/ithc-linux.git"
ITHC_COMMIT="6d53c9c21797df5da975bd27db22bd89ee0cead3"

KVER="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
KDIR="/usr/src/kernels/${KVER}"

if [[ ! -f "${KDIR}/Makefile" ]]; then
    echo "kernel-devel for ${KVER} is missing from the base image; cannot build ithc" >&2
    exit 1
fi

dnf5 install -y gcc make elfutils-libelf-devel

git clone --quiet "${ITHC_REPO}" /tmp/ithc
git -C /tmp/ithc checkout --quiet "${ITHC_COMMIT}"
make -C /tmp/ithc KDIR="${KDIR}"

mkdir -p /out
cp /tmp/ithc/build/ithc.ko /out/ithc.ko

# Sign the module so it loads with Secure Boot enabled. The key arrives as a
# build secret (PEM with private key + certificate) and never touches a layer.
if [[ -s /run/secrets/mok_key ]]; then
    "${KDIR}/scripts/sign-file" sha256 /run/secrets/mok_key /run/secrets/mok_key /out/ithc.ko
    tail -c 28 /out/ithc.ko | grep -q "~Module signature appended~"
else
    echo "WARNING: no mok_key secret; ithc.ko is unsigned and will not load with Secure Boot on" >&2
fi

echo "${KVER}" > /out/kver
