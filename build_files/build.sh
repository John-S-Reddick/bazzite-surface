#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Surface Pro 9 touchscreen + pen driver (built in the ithc stage of the Containerfile)

KVER="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

if [[ "$(cat /ithc/kver)" != "${KVER}" ]]; then
    echo "ithc was built for $(cat /ithc/kver) but the image kernel is ${KVER}" >&2
    exit 1
fi

install -D -m 0644 /ithc/ithc.ko "/usr/lib/modules/${KVER}/extra/ithc/ithc.ko"
depmod -a "${KVER}"
modinfo -k "${KVER}" ithc

### iptsd - turns raw touch/pen data from ithc into multitouch and stylus input

# linux-surface has not published a Fedora 44 repo, so pin to their Fedora 43 one.
# iptsd's library dependencies (fmt 11, spdlog 1.15, inih) are the same on 44.
cat > /etc/yum.repos.d/linux-surface.repo <<'EOF'
[linux-surface]
name=linux-surface
baseurl=https://pkg.surfacelinux.com/fedora/f43/
enabled=1
gpgkey=https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc
gpgcheck=1
repo_gpgcheck=0
EOF

dnf5 install -y iptsd

# Keep the repo out of the final image so nothing on the Surface tracks it
rm -f /etc/yum.repos.d/linux-surface.repo

# iptsd is started per-device by its udev rule (50-iptsd.rules), so there is no unit to enable
test -f /usr/lib/udev/rules.d/50-iptsd.rules
