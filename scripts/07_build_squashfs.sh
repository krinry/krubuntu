#!/bin/bash
# Krubuntu Build Engine - 07_build_squashfs.sh
# Extracts kernel/initrd, stages Casper live layout, and compiles SquashFS root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/distro.conf"

BUILD_DIR="${PROJECT_ROOT}/build"
CHROOT_DIR="${BUILD_DIR}/chroot"
IMAGE_DIR="${BUILD_DIR}/image"
CASPER_DIR="${IMAGE_DIR}/casper"
DISK_DIR="${IMAGE_DIR}/.disk"

echo "=== [Step 7] Staging Casper Image & Compiling SquashFS ==="

mkdir -p "${CASPER_DIR}" "${DISK_DIR}"

# 1. Extract Kernel and Initrd
echo "Copying kernel binary and initramfs to Casper staging area..."
LATEST_VMLINUZ=$(ls -1t "${CHROOT_DIR}/boot"/vmlinuz-* 2>/dev/null | head -n 1)
LATEST_INITRD=$(ls -1t "${CHROOT_DIR}/boot"/initrd.img-* 2>/dev/null | head -n 1)

if [ -z "${LATEST_VMLINUZ}" ] || [ -z "${LATEST_INITRD}" ]; then
    echo "ERROR: Kernel or Initrd image not found in ${CHROOT_DIR}/boot!"
    exit 1
fi

echo "Using Kernel:  ${LATEST_VMLINUZ}"
echo "Using Initrd:  ${LATEST_INITRD}"

cp -f "${LATEST_VMLINUZ}" "${CASPER_DIR}/vmlinuz"
cp -f "${LATEST_INITRD}" "${CASPER_DIR}/initrd"

# 2. Casper Disc Identification
echo "Writing Casper medium identifiers..."
echo "${DISTRO_NAME} ${DISTRO_VERSION} ${DISTRO_EDITION} - amd64" > "${DISK_DIR}/info"
touch "${DISK_DIR}/base_installable"

# 3. Generate Manifest
echo "Generating filesystem manifest..."
chroot "${CHROOT_DIR}" dpkg-query -W --showformat='${Package} ${Version}\n' > "${CASPER_DIR}/filesystem.manifest"
cp -f "${CASPER_DIR}/filesystem.manifest" "${CASPER_DIR}/filesystem.manifest-remove"

# 4. Compile SquashFS Filesystem
echo "Compressing RootFS with ${SQUASHFS_COMP} (This may take several minutes)..."
rm -f "${CASPER_DIR}/filesystem.squashfs"

# Exclude boot directory from inside squashfs to save space (it's already staged in casper)
mksquashfs "${CHROOT_DIR}" "${CASPER_DIR}/filesystem.squashfs" \
    -comp "${SQUASHFS_COMP}" \
    -noappend \
    -e "${CHROOT_DIR}/boot"

# Calculate uncompressed size in bytes for Casper installer
printf $(du -sx --block-size=1 "${CHROOT_DIR}" | cut -f1) > "${CASPER_DIR}/filesystem.size"

echo "SquashFS compiled successfully. Image size: $(du -sh "${CASPER_DIR}/filesystem.squashfs" | cut -f1)"
