#!/bin/bash
# Krubuntu Build Engine - 05_install_calamares.sh
# Deploys custom Calamares installer configuration, modules, and Krubuntu branding.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CHROOT_DIR="${PROJECT_ROOT}/build/chroot"
CALAMARES_CFG_DIR="${PROJECT_ROOT}/config/calamares"

echo "=== [Step 5] Deploying Calamares Installer & Krubuntu Branding ==="

mkdir -p "${CHROOT_DIR}/etc/calamares/branding/krubuntu"
mkdir -p "${CHROOT_DIR}/etc/calamares/modules"
mkdir -p "${CHROOT_DIR}/usr/share/icons/hicolor/scalable/apps"

# 1. Main settings
echo "Installing Calamares settings..."
cp -f "${CALAMARES_CFG_DIR}/settings.conf" "${CHROOT_DIR}/etc/calamares/settings.conf"

# 2. Krubuntu Branding profile
echo "Installing Krubuntu branding..."
cp -rf "${CALAMARES_CFG_DIR}/branding/krubuntu/"* "${CHROOT_DIR}/etc/calamares/branding/krubuntu/"

# 3. Custom Modules
echo "Installing custom Calamares modules..."
cp -rf "${CALAMARES_CFG_DIR}/modules/"* "${CHROOT_DIR}/etc/calamares/modules/"

# 4. System Icon & Logo
cp -f "${CALAMARES_CFG_DIR}/branding/krubuntu/krubuntu-logo.svg" "${CHROOT_DIR}/usr/share/icons/hicolor/scalable/apps/krubuntu-logo.svg"

echo "Calamares configuration deployed successfully."
