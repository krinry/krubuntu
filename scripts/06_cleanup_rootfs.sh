#!/bin/bash
# Krubuntu Build Engine - 06_cleanup_rootfs.sh
# Purges temporary caches, logs, history, and unmounts all virtual pipelines.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/02_mount_chroot.sh"

CHROOT_DIR="${PROJECT_ROOT}/build/chroot"

echo "=== [Step 6] Cleaning RootFS & Preparing for Compression ==="

# 1. Clean packages and caches inside chroot
CLEAN_SCRIPT="${CHROOT_DIR}/tmp/cleanup_inner.sh"

cat << 'EOF' > "${CLEAN_SCRIPT}"
#!/bin/bash
set -euo pipefail

echo "[chroot] Cleaning APT download caches (preserving AppStream metadata)..."
apt-get autoremove -y --purge 2>/dev/null || true
apt-get clean
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/cache/apt/*.bin

# Refresh AppStream metadata cache so Discover has all offline applications
appstreamcli refresh-cache --force 2>/dev/null || true

echo "[chroot] Cleaning temporary files and machine identifiers..."
rm -rf /tmp/* /tmp/.* 2>/dev/null || true
rm -rf /var/tmp/* 2>/dev/null || true
rm -f /etc/machine-id /var/lib/dbus/machine-id
touch /etc/machine-id

# Clear bash history
rm -f /root/.bash_history
rm -f /home/*/.bash_history 2>/dev/null || true

echo "[chroot] Inner cleanup completed."
EOF

chmod +x "${CLEAN_SCRIPT}"

# Execute inner cleanup
mount_virtual_fs "${CHROOT_DIR}"
trap 'unmount_virtual_fs "${CHROOT_DIR}"' EXIT INT TERM

chroot "${CHROOT_DIR}" /bin/bash /tmp/cleanup_inner.sh
rm -f "${CLEAN_SCRIPT}"

# Restore clean resolv.conf placeholder
rm -f "${CHROOT_DIR}/etc/resolv.conf"
ln -sf /run/systemd/resolve/stub-resolv.conf "${CHROOT_DIR}/etc/resolv.conf" 2>/dev/null || touch "${CHROOT_DIR}/etc/resolv.conf"

# Safely unmount all virtual filesystems
unmount_virtual_fs "${CHROOT_DIR}"
trap - EXIT INT TERM

# Critical Safety Check: Ensure placeholder directories exist for the kernel
echo "Verifying root skeleton mount point placeholders..."
mkdir -p "${CHROOT_DIR}/dev" "${CHROOT_DIR}/proc" "${CHROOT_DIR}/sys" "${CHROOT_DIR}/run" "${CHROOT_DIR}/tmp" "${CHROOT_DIR}/mnt" "${CHROOT_DIR}/media"

# Final verification that no mounts are attached to chroot
if mount | grep -q "${CHROOT_DIR}"; then
    echo "ERROR: Active mounts still detected inside ${CHROOT_DIR}!"
    mount | grep "${CHROOT_DIR}"
    exit 1
fi

echo "RootFS cleanup completed cleanly."
