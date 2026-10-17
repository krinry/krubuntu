# Krubuntu Distro Builder Container
# Provides a completely isolated, reproducible Ubuntu build environment.
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    debootstrap \
    squashfs-tools \
    xorriso \
    mtools \
    dosfstools \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-common \
    binutils \
    curl \
    wget \
    tar \
    gzip \
    xz-utils \
    ca-certificates \
    git \
    sudo \
    appstream \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash", "./build.sh", "--inner"]
