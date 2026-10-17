#!/bin/bash
# Krubuntu Build Engine - 08_build_iso.sh
# Assembles bootable UEFI + BIOS hybrid GRUB2 ISO image with MD5 checksums.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/distro.conf"

BUILD_DIR="${PROJECT_ROOT}/build"
IMAGE_DIR="${BUILD_DIR}/image"
OUTPUT_DIR="${PROJECT_ROOT}/output"
FINAL_ISO="${OUTPUT_DIR}/${ISO_OUTPUT_NAME}"

echo "=== [Step 8] Building Final Bootable Hybrid ISO ==="

# 1. Install GRUB configuration
echo "Staging GRUB 2 bootloader configuration..."
mkdir -p "${IMAGE_DIR}/boot/grub"
cp -f "${PROJECT_ROOT}/config/grub/grub.cfg" "${IMAGE_DIR}/boot/grub/grub.cfg"

# 2. Generate Casper MD5 checksum manifest
echo "Generating Casper md5sum.txt integrity check..."
(cd "${IMAGE_DIR}" && find . -type f ! -name "md5sum.txt" ! -path "*/boot.cat" ! -path "*/isolinux/*" -print0 | xargs -0 md5sum > md5sum.txt)

# 3. Create Hybrid ISO
echo "Packaging Hybrid UEFI + BIOS bootable ISO with grub-mkrescue / xorriso..."
rm -f "${FINAL_ISO}"

if command -v grub-mkrescue >/dev/null 2>&1; then
    grub-mkrescue -o "${FINAL_ISO}" "${IMAGE_DIR}" \
        -- -volid "${DISTRO_NAME}"
elif command -v xorriso >/dev/null 2>&1; then
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "${DISTRO_NAME}" \
        -output "${FINAL_ISO}" \
        "${IMAGE_DIR}"
else
    echo "ERROR: Neither grub-mkrescue nor xorriso is installed!"
    exit 1
fi

# 4. Generate SHA256 Checksum
echo "Generating SHA256 verification hash..."
(cd "${OUTPUT_DIR}" && sha256sum "${ISO_OUTPUT_NAME}" > "${ISO_OUTPUT_NAME}.sha256")

echo "=========================================================="
echo "SUCCESS! Krubuntu ISO built successfully:"
echo "File:   ${FINAL_ISO}"
echo "Size:   $(du -sh "${FINAL_ISO}" | cut -f1)"
echo "SHA256: $(cat "${FINAL_ISO}.sha256" | cut -d' ' -f1)"
echo "=========================================================="
