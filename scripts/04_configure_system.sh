#!/bin/bash
# Krubuntu Build Engine - 04_configure_system.sh
# Applies system identity, live user, SDDM autologin, and Discover policies.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/distro.conf"
source "${SCRIPT_DIR}/02_mount_chroot.sh"

CHROOT_DIR="${PROJECT_ROOT}/build/chroot"
OVERLAY_DIR="${PROJECT_ROOT}/config/rootfs-overlay"

echo "=== [Step 4] Configuring System & Live Environment ==="

# 1. Apply RootFS Overlay
echo "Applying RootFS overlay configuration..."
cp -r "${OVERLAY_DIR}/"* "${CHROOT_DIR}/"

# 2. Hostname and Hosts
echo "${LIVE_HOSTNAME}" > "${CHROOT_DIR}/etc/hostname"
cat << EOF > "${CHROOT_DIR}/etc/hosts"
127.0.0.1   localhost
127.0.1.1   ${LIVE_HOSTNAME}
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# 3. Inner System Configuration Script
CONFIG_SCRIPT="${CHROOT_DIR}/tmp/configure_inner.sh"

cat << EOF > "${CONFIG_SCRIPT}"
#!/bin/bash
set -euo pipefail

# Live User Creation
echo "[chroot] Setting up live user account: ${LIVE_USER}..."
groupadd "${LIVE_USER}" 2>/dev/null || true
useradd -m -s /bin/bash -g "${LIVE_USER}" "${LIVE_USER}" 2>/dev/null || usermod -g "${LIVE_USER}" "${LIVE_USER}"

echo "${LIVE_USER}:${LIVE_PASSWORD}" | chpasswd
echo "root:${LIVE_PASSWORD}" | chpasswd

# Autologin and device groups
groupadd -r autologin 2>/dev/null || true
groupadd -r nopasswdlogin 2>/dev/null || true

for grp in sudo autologin nopasswdlogin video render audio input plugdev netdev bluetooth; do
    groupadd -r "\${grp}" 2>/dev/null || true
    usermod -aG "\${grp}" "${LIVE_USER}" 2>/dev/null || true
done

# Passwordless sudo for live session with GUI display preservation
cat << EOF_SUDO > /etc/sudoers.d/krubuntu-live
${LIVE_USER} ALL=(ALL) NOPASSWD: ALL
Defaults:${LIVE_USER} env_keep += "DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_RUNTIME_DIR"
EOF_SUDO
chmod 0440 /etc/sudoers.d/krubuntu-live


# Live Desktop Setup (Installer shortcut placed ONLY on live user desktop)
mkdir -p "/home/${LIVE_USER}/Desktop"
if [ -f /usr/share/applications/install-krubuntu.desktop ]; then
    cp -f /usr/share/applications/install-krubuntu.desktop "/home/${LIVE_USER}/Desktop/"
    chmod +x "/home/${LIVE_USER}/Desktop/install-krubuntu.desktop"
fi
rm -f /etc/skel/Desktop/install-krubuntu.desktop 2>/dev/null || true
chown -R "${LIVE_USER}:${LIVE_USER}" "/home/${LIVE_USER}"

# Ensure Casper live directories exist
mkdir -p /var/crash /usr/lib/update-notifier /usr/lib/ubuntu-release-upgrader /etc/default
touch /etc/default/apport
mkdir -p /usr/sbin
ln -sf /bin/true /usr/sbin/install-keymap

# Hardware & Desktop Services Enable
systemctl enable sddm 2>/dev/null || true
systemctl enable NetworkManager 2>/dev/null || true
systemctl enable systemd-resolved 2>/dev/null || true
systemctl enable bluetooth 2>/dev/null || true
systemctl enable power-profiles-daemon 2>/dev/null || true
systemctl enable earlyoom 2>/dev/null || true
systemctl enable fstrim.timer 2>/dev/null || true
systemctl enable ufw 2>/dev/null || true
systemctl --user --global enable pipewire pipewire-pulse wireplumber 2>/dev/null || true

# Apply Netplan configuration for full NetworkManager device management
chmod 600 /etc/netplan/*.yaml 2>/dev/null || true
netplan generate 2>/dev/null || true

# Policy: Disable Snapd by default to eliminate background resource usage
echo "[chroot] Disabling snapd daemon by default (Available on demand)..."
systemctl disable snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true

# Policy: Configure Flathub Flatpak remote (Disabled by default, toggleable in Discover)
echo "[chroot] Adding Flathub remote as disabled by default (Toggleable via Discover)..."
mkdir -p /var/lib/flatpak/repo
flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-modify --system --disable flathub 2>/dev/null || true

# Update AppStream metadata cache
appstreamcli refresh-cache --force 2>/dev/null || true

# Mask casper-md5check to avoid live boot halt if integrity check bypassed
systemctl mask casper-md5check.service 2>/dev/null || true

echo "[chroot] System configuration applied."
EOF

chmod +x "${CONFIG_SCRIPT}"

# Execute inner config inside chroot
mount_virtual_fs "${CHROOT_DIR}"
trap 'unmount_virtual_fs "${CHROOT_DIR}"' EXIT INT TERM

chroot "${CHROOT_DIR}" /bin/bash /tmp/configure_inner.sh
rm -f "${CONFIG_SCRIPT}"

unmount_virtual_fs "${CHROOT_DIR}"
trap - EXIT INT TERM

echo "System configuration stage finished."
