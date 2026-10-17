#!/bin/bash
# Krubuntu Build Engine - 01_bootstrap.sh
# Acquires base root filesystem and initializes bootstrap.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/distro.conf"

BUILD_DIR="${PROJECT_ROOT}/build"
CHROOT_DIR="${BUILD_DIR}/chroot"
CACHE_DIR="${PROJECT_ROOT}/cache"
TARBALL_PATH="${CACHE_DIR}/${BASE_TARBALL}"

echo "=== [Step 1] Bootstrapping Base RootFS ==="

# Check if base archive is in cache
if [ ! -f "${TARBALL_PATH}" ]; then
    echo "Base archive not found in cache. Downloading official Ubuntu Base ${DISTRO_CODENAME}..."
    curl -L --fail -o "${TARBALL_PATH}" "${BASE_URL}" || {
        echo "Direct download failed. Trying alternative mirror..."
        wget -c "${BASE_URL}" -O "${TARBALL_PATH}"
    }
else
    echo "Found cached base archive: ${TARBALL_PATH}"
fi

# Extract into chroot
if [ ! -f "${CHROOT_DIR}/bin/bash" ]; then
    echo "Extracting rootfs into ${CHROOT_DIR}..."
    tar -xzf "${TARBALL_PATH}" -C "${CHROOT_DIR}"
    echo "Extraction complete."
else
    echo "Chroot rootfs already extracted, skipping re-extraction."
fi

# Setup DNS for internet access inside chroot
rm -f "${CHROOT_DIR}/etc/resolv.conf"
if [ -f /etc/resolv.conf ]; then
    cp -L /etc/resolv.conf "${CHROOT_DIR}/etc/resolv.conf"
else
    echo "nameserver 1.1.1.1" > "${CHROOT_DIR}/etc/resolv.conf"
    echo "nameserver 8.8.8.8" >> "${CHROOT_DIR}/etc/resolv.conf"
fi

# Copy host/container SSL certificates to chroot if present
if [ -d /etc/ssl/certs ]; then
    mkdir -p "${CHROOT_DIR}/etc/ssl/certs"
    cp -rf /etc/ssl/certs/* "${CHROOT_DIR}/etc/ssl/certs/" 2>/dev/null || true
fi

# Configure official base APT repositories
echo "Configuring official APT repositories and keyrings..."
rm -f "${CHROOT_DIR}/etc/apt/sources.list.d/ubuntu.sources" 2>/dev/null || true
cp -f "${PROJECT_ROOT}/config/apt/sources.list" "${CHROOT_DIR}/etc/apt/sources.list"

mkdir -p "${CHROOT_DIR}/etc/apt/keyrings"
if [ -d "${PROJECT_ROOT}/config/apt/keyrings" ]; then
    cp -rf "${PROJECT_ROOT}/config/apt/keyrings/"* "${CHROOT_DIR}/etc/apt/keyrings/" 2>/dev/null || true
fi

echo "Bootstrap stage finished successfully."

