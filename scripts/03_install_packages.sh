#!/bin/bash
# Krubuntu Build Engine - 03_install_packages.sh
# Installs minimal KDE desktop, Calamares, drivers, and Discover backends.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/distro.conf"
source "${SCRIPT_DIR}/02_mount_chroot.sh"

CHROOT_DIR="${PROJECT_ROOT}/build/chroot"
PACKAGES_FILE="${PROJECT_ROOT}/config/packages.list"

echo "=== [Step 3] Installing Packages inside Chroot ==="

# Sync APT keyrings into chroot
mkdir -p "${CHROOT_DIR}/etc/apt/keyrings"
if [ -d "${PROJECT_ROOT}/config/apt/keyrings" ]; then
    cp -rf "${PROJECT_ROOT}/config/apt/keyrings/"* "${CHROOT_DIR}/etc/apt/keyrings/" 2>/dev/null || true
fi

# Stage third-party APT configurations into /tmp/apt-config inside chroot
mkdir -p "${CHROOT_DIR}/tmp/apt-config/sources.list.d"
mkdir -p "${CHROOT_DIR}/tmp/apt-config/preferences.d"
if [ -d "${PROJECT_ROOT}/config/apt/sources.list.d" ]; then
    cp -rf "${PROJECT_ROOT}/config/apt/sources.list.d/"* "${CHROOT_DIR}/tmp/apt-config/sources.list.d/" 2>/dev/null || true
fi
if [ -d "${PROJECT_ROOT}/config/apt/preferences.d" ]; then
    cp -rf "${PROJECT_ROOT}/config/apt/preferences.d/"* "${CHROOT_DIR}/tmp/apt-config/preferences.d/" 2>/dev/null || true
fi

# Read package list (strip comments and blank lines)
PACKAGES=$(grep -vE '^\s*#|^\s*$' "${PACKAGES_FILE}" | tr '\n' ' ')

# Prepare installation script to execute inside chroot
INSTALL_SCRIPT="${CHROOT_DIR}/tmp/install_packages_inner.sh"

cat << 'EOF' > "${INSTALL_SCRIPT}"
#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

echo "[chroot] Updating base APT repositories..."
apt-get update

echo "[chroot] Setting up basic locales and SSL certificates..."
apt-get install -y --no-install-recommends locales ca-certificates curl gnupg
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
update-ca-certificates || true

echo "[chroot] Activating third-party repositories and preferences..."
mkdir -p /etc/apt/sources.list.d /etc/apt/preferences.d
if [ -d /tmp/apt-config/sources.list.d ]; then
    cp -rf /tmp/apt-config/sources.list.d/* /etc/apt/sources.list.d/ 2>/dev/null || true
fi
if [ -d /tmp/apt-config/preferences.d ]; then
    cp -rf /tmp/apt-config/preferences.d/* /etc/apt/preferences.d/ 2>/dev/null || true
fi
rm -rf /tmp/apt-config

echo "[chroot] Updating APT repositories with verified SSL certificates..."
apt-get update

# Read package list passed via arguments
PACKAGES="$@"
echo "[chroot] Installing curated software stack..."
apt-get install -y --no-install-recommends ${PACKAGES}

echo "[chroot] Configuring initramfs modules for Casper live boot & hardware storage..."
mkdir -p /etc/initramfs-tools
cat << 'MODULES' >> /etc/initramfs-tools/modules
overlay
squashfs
isofs
vfat
nls_cp437
nls_iso8859_1
uas
usb_storage
nvme
ahci
MODULES

# Remove any duplicate lines in modules
sort -u /etc/initramfs-tools/modules -o /etc/initramfs-tools/modules

echo "[chroot] Patching Casper live boot hooks & creating missing directory stubs..."
mkdir -p /var/crash
mkdir -p /usr/lib/update-notifier
mkdir -p /usr/lib/ubuntu-release-upgrader
mkdir -p /etc/default
touch /etc/default/apport
mkdir -p /usr/sbin
ln -sf /bin/true /usr/sbin/install-keymap

# Fix SDDM session name in Casper 15autologin (plasma instead of plasma.desktop)
if [ -f /usr/share/initramfs-tools/scripts/casper-bottom/15autologin ]; then
    sed -i 's/sddm_session=plasma.desktop/sddm_session=plasma/g' /usr/share/initramfs-tools/scripts/casper-bottom/15autologin
fi

# Ensure Wayland session aliases exist
mkdir -p /usr/share/wayland-sessions
ln -sf plasma.desktop /usr/share/wayland-sessions/plasma.desktop.desktop 2>/dev/null || true
ln -sf plasma.desktop /usr/share/wayland-sessions/plasma 2>/dev/null || true

# Permanently remove unwanted script that runs apt-get update in initramfs during live boot
rm -f /usr/share/initramfs-tools/scripts/casper-bottom/41apt_build_cache_cdrom

echo "[chroot] Updating initramfs for all installed kernels..."
update-initramfs -u -k all

echo "[chroot] Package installation completed successfully."
EOF

chmod +x "${INSTALL_SCRIPT}"

# Execute with mounts handled safely
mount_virtual_fs "${CHROOT_DIR}"
trap 'unmount_virtual_fs "${CHROOT_DIR}"' EXIT INT TERM

chroot "${CHROOT_DIR}" /bin/bash /tmp/install_packages_inner.sh ${PACKAGES}
rm -f "${INSTALL_SCRIPT}"

unmount_virtual_fs "${CHROOT_DIR}"
trap - EXIT INT TERM

echo "Package installation stage finished."
