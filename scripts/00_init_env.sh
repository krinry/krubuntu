#!/bin/bash
# Krubuntu Build Engine - 00_init_env.sh
# Validates host environment, directories, configuration, and tools.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source Configuration
source "${PROJECT_ROOT}/config/distro.conf"

echo "=== [Step 0] Initializing Krubuntu Build Environment ==="
echo "Distro: ${DISTRO_NAME} ${DISTRO_VERSION} (${DISTRO_CODENAME})"
echo "Working Directory: ${PROJECT_ROOT}"

# Directories
BUILD_DIR="${PROJECT_ROOT}/build"
CHROOT_DIR="${BUILD_DIR}/chroot"
IMAGE_DIR="${BUILD_DIR}/image"
CASPER_DIR="${IMAGE_DIR}/casper"
DISK_DIR="${IMAGE_DIR}/.disk"
GRUB_DIR="${IMAGE_DIR}/boot/grub"
OUTPUT_DIR="${PROJECT_ROOT}/output"
CACHE_DIR="${PROJECT_ROOT}/cache"

mkdir -p "${CHROOT_DIR}" "${CASPER_DIR}" "${DISK_DIR}" "${GRUB_DIR}" "${OUTPUT_DIR}" "${CACHE_DIR}"

# Check available disk space (at least 10GB recommended)
AVAIL_KB=$(df -k --output=avail "${PROJECT_ROOT}" | tail -n 1)
AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
echo "Available Disk Space: ${AVAIL_GB} GB"

if [ "${AVAIL_GB}" -lt 8 ]; then
    echo "WARNING: Low disk space detected (<8 GB). Build may fail during squashfs compression."
fi

echo "Environment initialized successfully."
