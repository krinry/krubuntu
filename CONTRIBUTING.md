# Contributing to Krubuntu

Thank you for your interest in contributing to **Krubuntu**! We welcome bug reports, hardware compatibility feedback, documentation improvements, and code contributions from the open-source community.

---

## 1. Core Principles

Before opening a pull request, please keep our core tenets in mind:
* **Zero Bloatware:** We do not accept PRs adding pre-installed games, non-essential duplicate media players, commercial software, or telemetry daemons.
* **Infrastructure-as-Code (Strictly No Cubic):** All modifications must be reproducible, version-controlled scripts or configuration overlays. We do not accept binary-patched chroot images or undocumented modifications.
* **KDE Plasma & Wayland First:** Krubuntu targets modern, performant KDE Plasma on Wayland with seamless hardware acceleration.
* **User Agency:** Snap and Flatpak must remain optional and user-controlled.

---

## 2. Development Setup

### Prerequisites
* A Linux workstation (Ubuntu, Debian, Fedora, Arch, etc.)
* Git installed
* Docker or Podman installed (recommended for non-Ubuntu hosts)
* QEMU (`qemu-system-x86_64`) for testing built ISOs

### Clone the Repository
```bash
git clone https://github.com/krinry/krubuntu.git
cd krubuntu
```

---

## 3. Building & Testing Locally

### Option A: Isolated Container Build (Recommended)
This runs the entire build process inside an isolated Ubuntu 26.04 builder container without altering your host system:
```bash
./build.sh --docker
```

### Option B: Host System Build (Ubuntu/Debian Hosts)
```bash
sudo ./build.sh --host
```

### Testing the ISO in QEMU
Once built, verify the ISO in QEMU with full KVM hardware acceleration, Intel HDA duplex audio, network, and virtual disk:
```bash
./build.sh --test
```

---

## 4. Codebase Organization

* **`config/packages.list`**: Curated list of all packages installed into the root filesystem. Add minimal, essential packages here.
* **`config/distro.conf`**: Distribution metadata, kernel naming, and compression configurations (`SQUASHFS_COMP="zstd"`).
* **`config/rootfs-overlay/`**: Any file placed here is directly copied into the target root filesystem (e.g. `/etc/sysctl.d/`, `/etc/netplan/`, `/etc/environment`).
* **`config/calamares/`**: Calamares installer configuration, branding SVG icons, QML slideshows, and module descriptors.
* **`scripts/`**: Sequential build stages executed during ISO generation:
  * `00_init_env.sh` - Dependency verification.
  * `01_bootstrap.sh` - Base rootfs extraction.
  * `02_mount_chroot.sh` - Bind mounting with exit traps.
  * `03_install_packages.sh` - Package installation and kernel/initramfs setup.
  * `04_configure_system.sh` - Users, SDDM, systemd units, Discover policies.
  * `05_install_calamares.sh` - Calamares deployment.
  * `06_cleanup_rootfs.sh` - Sanitization and chroot unmounting.
  * `07_build_squashfs.sh` - SquashFS compression.
  * `08_build_iso.sh` - GRUB 2 hybrid UEFI/BIOS ISO packaging.

---

## 5. Commit & Pull Request Guidelines

### Commit Messages
We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
* `feat(scope): add new feature`
* `fix(scope): resolve a bug or regression`
* `docs(scope): documentation changes`
* `perf(scope): performance improvements`
* `ci(scope): GitHub Actions or build pipeline changes`
* `refactor(scope): code restructuring without feature change`

### Submitting a Pull Request
1. Fork the repository and create your feature branch:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. Make your changes and test the build thoroughly (`./build.sh --docker && ./build.sh --test`).
3. Commit your changes with clear, descriptive commit messages.
4. Push to your fork and submit a Pull Request against the `main` branch.
5. GitHub Actions will automatically run the CI build pipeline to verify that your changes compile into a bootable ISO.
