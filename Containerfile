ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite:stable

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

### ITHC MODULE BUILD
## The Surface Pro 9 touchscreen and pen sit behind the Intel Touch Host Controller,
## which mainline kernels (and therefore Bazzite's kernel) only drive on Meteor Lake
## and newer. Build the out-of-tree ithc driver against Bazzite's own kernel here, so
## the compiler toolchain never ends up in the final image.
FROM ${BASE_IMAGE} AS ithc

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=secret,id=mok_key \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-ithc.sh

# Base Image
FROM ${BASE_IMAGE}

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=ithc,source=/out,target=/ithc \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
