# Krubuntu Package Management & Software Policy

Krubuntu follows a user-centric software policy designed to provide maximum freedom, top performance, and zero bloatware. This document outlines our repository architecture, application curation, and management of Snap, Flatpak, and Native DEB software.

---

## 1. Zero Bloatware Guarantee

Mainstream distributions often ship with dozens of pre-installed applications, duplicate utilities, third-party promotional software, and background telemetry daemons.

Krubuntu adheres to a strict **Minimal Curation Standard**:
* **No Pre-Installed Games:** Zero casual games or demos.
* **No Telemetry or Tracking:** Canonical `popularity-contest`, `apport` crash report uploading, and Ubuntu telemetry agents are removed or disabled.
* **One Best-in-Class App per Category:**
  * **Web Browser:** Native Mozilla Firefox (`.deb`).
  * **Document Viewer:** Okular (Universal PDF, ePub, PostScript viewer).
  * **Media Playback:** VLC & FFmpeg (100% universal codec coverage).
  * **File Management:** Dolphin (with native compression, terminal, and MTP integration).
  * **Terminal:** Konsole (zsh/bash, tabbed, split view).
  * **Text Editor:** KWrite (syntax highlighting, UTF-8).
  * **Screenshot Tool:** Spectacle (Wayland screen capture, region crop, annotations).
  * **Archive Manager:** Ark (zip, tar, 7z, rar, zstd).
  * **Image Viewer:** Gwenview (fast JPEG/PNG/WebP/AVIF display).
  * **Partition Manager:** KDE Partition Manager.

---

## 2. The Snap Policy

Standard Ubuntu releases increasingly force Snap packages, often replacing familiar `apt install <app>` commands with background Snap daemon downloads. While Snap provides sandboxing, it introduces noticeable startup delays, loop mount pollution (`/dev/loop*`), and continuous background memory usage.

### 2.1 Our Approach
* **Snapd is Included:** The `snapd` runtime and `plasma-discover-backend-snap` are installed so you do not have to manually configure repositories if you need Snap.
* **Disabled at Boot by Default:** The `snapd.service` and `snapd.socket` are disabled on initial boot, saving **~150MB - 250MB of RAM** and reducing system boot time.
* **APT Pinning (`nosnap.pref`):**
  We inject `/etc/apt/preferences.d/nosnap.pref`:
  ```text
  Package: snapd
  Pin: release *
  Pin-Priority: -1
  ```
  This prevents `apt` from automatically installing snap packages behind your back when installing native utilities.
* **User Control:** If you want Snap packages, you can enable them at any time with a single click in KDE Discover Settings or via `krubuntu-backend-manager`.

---

## 3. The Flatpak & Flathub Policy

Flatpak has emerged as the premier open-source desktop packaging format for Linux, offering superior sandboxing, direct developer distribution, and native Wayland integration.

### 3.1 Pre-Configured, Disabled by Default
* `flatpak` and the KDE Discover backend (`plasma-discover-backend-flatpak`) are pre-installed.
* The official **Flathub** repository remote is added to the system during build time, but set to **`disabled=true`**.
* **Zero Overhead:** In this state, Flathub performs zero background network updates, consumes zero RAM, and does not check for updates until you choose to activate it.

### 3.2 How to Enable Flathub (GUI):
1. Launch **Discover** from the application launcher.
2. Click **Settings** in the bottom-left corner.
3. Under the **Sources** heading, find **Flathub**.
4. Check the box to activate. Millions of apps (Spotify, Discord, VS Code, Steam, OBS Studio) will immediately become searchable and installable with one click!

Alternatively, run **Software Backends Manager** (`krubuntu-backend-manager`) from the application menu or terminal to toggle Flatpak with a single switch.

---

## 4. Native Mozilla Firefox APT Repository

In Ubuntu 26.04, the default `firefox` package in Ubuntu repositories is a transitional dummy package that forcibly installs the Snap version.

Krubuntu bypasses this by integrating the official **Mozilla Signed APT Repository**:
1. **Mozilla Official Signing Key:** Verified cryptographic keyring installed at `/etc/apt/keyrings/packages.mozilla.org.asc`.
2. **Repository Source:** `/etc/apt/sources.list.d/mozilla.sources` pointing to `https://packages.mozilla.org/apt`.
3. **APT Priority Pinning:** `/etc/apt/preferences.d/mozilla.pref` assigns priority `1001` to Mozilla's official `.deb` builds.

### Benefits:
* **Instant Startup:** Launches in <1 second (no snap daemon initialization).
* **Direct Mozilla Updates:** Receives zero-day security updates directly from Mozilla's release pipeline.
* **Full Wayland Integration:** Native Wayland surface rendering and VA-API hardware video acceleration.
* **Audio & Mic:** Native PipeWire audio streaming without sandbox permission hurdles.

---

## 5. Offline Software Catalog & Discover Integration

* **2,600+ Cached AppStream Entries:** Discover includes an offline database of available open-source software, allowing you to browse categories, descriptions, and screenshots even without an active internet connection.
* **Firmware Updates via fwupd:** Krubuntu includes `plasma-discover-backend-fwupd` connected to the Linux Vendor Firmware Service (LVFS). Discover alerts you when motherboard BIOS, SSD firmware, or peripheral updates are available, allowing secure firmware flashing directly from the desktop.
