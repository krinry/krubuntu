# Krubuntu Hardware Enablement & Driver Compatibility

Krubuntu is engineered to provide flawless out-of-the-box hardware enablement across desktop PCs, modern laptops, workstations, and virtual machines without requiring manual driver compilation or post-install troubleshooting.

---

## 1. Hardware Support Matrix

| Hardware Category | Subsystem / Stack | Key Packages | Compatibility |
| :--- | :--- | :--- | :--- |
| **Audio & Microphones** | PipeWire 1.6 + WirePlumber | `pipewire`, `wireplumber`, `pipewire-audio`, `pipewire-alsa`, `pipewire-pulse`, `libspa-0.2-bluetooth` | Out of the Box |
| **Audio DSP & Firmware** | Intel SOF / AMD ACP | `firmware-sof-signed`, `alsa-ucm-conf` | Out of the Box |
| **Intel Graphics** | Mesa 24.x + VA-API | `mesa-vulkan-drivers`, `intel-media-va-driver`, `libva2` | Out of the Box (Iris Xe, Arc, HD Graphics) |
| **AMD Radeon Graphics** | Mesa 24.x + RADV | `mesa-vulkan-drivers`, `mesa-va-drivers`, `libdrm-amdgpu1` | Out of the Box (RDNA 1/2/3, GCN) |
| **NVIDIA Graphics** | Nouveau (Open) + Proprietary | `mesa-vulkan-drivers`, `ubuntu-drivers-common` | Nouveau OOTB; Proprietary via Driver Manager |
| **Wireless & Wi-Fi** | NetworkManager + WPA3 | `network-manager`, `wpasupplicant`, `linux-firmware` | Wi-Fi 4/5/6/6E/7 (Intel, Realtek, Broadcom, MediaTek) |
| **Bluetooth & Peripherals** | BlueZ + BlueDevil | `bluez`, `bluedevil`, `pulseaudio-utils` | Bluetooth 4.0 - 5.4, LE Audio, A2DP |
| **Storage & USB Drives** | Native Kernel + User Tools | `nvme-cli`, `ntfs-3g`, `exfatprogs`, `dosfstools`, `e2fsprogs` | NVMe, SATA SSD, HDD, USB Flash Drives, SD Cards |
| **Power & Thermal** | Freedesktop Power Profiles | `power-profiles-daemon`, `powerdevil`, `brightnessctl` | Intel RAPL, AMD P-State, ACPI Battery |
| **Display & Monitors** | KScreen + Wayland | `kscreen`, `kwin-wayland`, `qtwayland5`, `qt6-wayland` | Multi-Monitor, HiDPI Fractional Scaling, VRR/FreeSync |

---

## 2. Audio & Microphone Engine

Modern laptops (particularly Intel 10th Gen through 14th+ Gen and AMD Ryzen 5000/6000/7000/8000 series) use digital signal processors (DSP) and complex audio amplifier routing rather than legacy analog audio jacks.

### 2.1 Intel Sound Open Firmware (SOF)
Krubuntu bundles the latest signed firmware binaries (`firmware-sof-signed`) for Intel smart sound hardware:
* Automatically initialized via the kernel `snd_sof_pci_intel_*` driver.
* Enables digital internal stereo microphone arrays on modern thin-and-light laptops.
* Eliminates the common "Dummy Output" issue prevalent in standard minimal distributions.

### 2.2 ALSA Use Case Manager (UCM)
Hardware topology profiles provided by `alsa-ucm-conf` define exact pin routing for:
* Automatic headphone jack insertion and removal detection.
* Internal microphone vs. external headset microphone switching.
* High-definition speaker amplifier volume curves without digital clipping.

### 2.3 Bluetooth High-Definition Audio
Powered by PipeWire's `libspa-0.2-bluetooth` module, Krubuntu supports:
* **Codecs:** LDAC, AptX, AptX-HD, AAC, SBC-XQ, and standard SBC.
* **Profiles:** A2DP (High quality playback) and HFP/HSP (Headset calling with microphone).
* **Automatic Codec Negotiation:** Always selects the highest-fidelity codec supported by connected wireless headphones.

---

## 3. Graphics & Hardware Video Acceleration

### 3.1 Mesa Vulkan 1.3
The `mesa-vulkan-drivers` stack provides low-overhead Vulkan 1.3 graphics rendering:
* **Intel:** ANV Vulkan driver supporting Intel HD Graphics, Iris Xe, and Intel Arc dedicated GPUs.
* **AMD:** RADV high-performance Vulkan driver for AMD Radeon RX 5000, 6000, 7000, and integrated Ryzen APUs.
* **Proton / Gaming Ready:** Seamlessly compatible with Steam Proton, Wine, Lutris, and Heroic Games Launcher.

### 3.2 Hardware Video Decode (VA-API)
Hardware video decoding is enabled via `intel-media-va-driver` and `mesa-va-drivers`:
* Offloads H.264, HEVC (H.265), VP9, and AV1 video decode directly to the GPU.
* Minimizes CPU utilization during 4K YouTube playback in Firefox, saving battery life and keeping laptops cool.
* VLC and FFmpeg are pre-configured to utilize VA-API hardware acceleration automatically.

### 3.3 NVIDIA GPU Compatibility
Krubuntu ships with open-source Mesa Nouveau drivers for boot and live session display. For gaming and CUDA workloads on NVIDIA RTX/GTX GPUs:
```bash
# Detect and install recommended proprietary NVIDIA drivers
sudo ubuntu-drivers install
```

---

## 4. Networking, Wi-Fi & Bluetooth

### 4.1 Netplan Delegation to NetworkManager
Ubuntu 26.04 minimal utilizes Netplan for network management. In Krubuntu, Netplan is configured to delegate 100% of network interfaces to NetworkManager:
```yaml
# /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: NetworkManager
```
And NetworkManager is configured with `managed=true` and `unmanaged-devices=none` in `/etc/NetworkManager/NetworkManager.conf`. This guarantees:
* Ethernet ports automatically acquire IP addresses via DHCP upon cable connection.
* Wi-Fi interfaces immediately show available SSIDs in the KDE Plasma system tray.
* No conflict between Netplan systemd-networkd and NetworkManager.

### 4.2 Wi-Fi 6 / 6E / 7 & WPA3
The `wpasupplicant` daemon and full `linux-firmware` package enable:
* WPA3-Personal (SAE) and WPA3-Enterprise security.
* Fast BSS Transition (802.11r) for seamless roaming between access points.
* Support for 2.4 GHz, 5 GHz, and 6 GHz spectrum bands.

---

## 5. Storage, Filesystems & Removable Media

External storage drives and multi-boot Windows partitions work instantly upon plug-in:
* **NTFS-3G (`ntfs-3g`):** Full read and write support for Windows external drives, internal Windows C: drives, and dual-boot volumes.
* **exFAT (`exfatprogs`):** Native read/write support for modern high-capacity SD cards, USB 3.2 flash drives, and external SSDs.
* **FAT32 / FAT16 (`dosfstools`):** Standard EFI System Partitions and universal USB drives.
* **MTP Smartphone File Transfer (`kio-extras`):** Connect Android or iOS devices via USB to browse photos and transfer files directly inside Dolphin.
* **Initramfs Storage Drivers:** Pre-loads `nvme`, `ahci`, `uas`, and `usb_storage` kernel modules so bare-metal NVMe drives and USB external boot drives are recognized instantly during boot.

---

## 6. Power Management & Laptop Enablement

* **Dynamic Power Profiles (`power-profiles-daemon`):**
  Accessible directly from the KDE Plasma battery widget. Select between:
  1. **Power Saver:** Lowers CPU clock limits, dims screen, extends battery life.
  2. **Balanced:** Adaptive governor scaling for daily productivity.
  3. **Performance:** Maximum CPU/GPU boost clocks for gaming and compilation.
* **Hardware Brightness (`brightnessctl`):**
  Controls display backlights across AMD, Intel, and external DDC/CI monitors without lag or permission errors.
* **Multi-Touch Gestures:**
  Full 1:1 Wayland multi-touch touchpad gestures (3-finger swipe for virtual desktops, pinch-to-zoom, 4-finger swipe for overview).
