#!/bin/bash
# Krubuntu Master Build System
# Automated, reproducible distribution builder.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${PROJECT_ROOT}/config/distro.conf"

MODE="auto"
TARGET_STAGE="all"

print_banner() {
    echo "=========================================================="
    echo "            KRUBUNTU DISTRO BUILD SYSTEM                  "
    echo "          Version: ${DISTRO_VERSION} (${DISTRO_CODENAME}) "
    echo "=========================================================="
}

run_docker_build() {
    echo "--> Running Krubuntu build in isolated Docker container..."
    local image_tag="krubuntu-builder:26.04"

    # Build builder image if needed
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image_tag}$"; then
        echo "Building local builder container: ${image_tag}..."
        docker build -t "${image_tag}" -f "${PROJECT_ROOT}/Dockerfile" "${PROJECT_ROOT}"
    fi

    echo "Launching containerized build..."
    docker run --rm -i \
        --privileged \
        -v "${PROJECT_ROOT}:/workspace" \
        "${image_tag}" \
        /bin/bash ./build.sh --inner 2>&1 | tee "${PROJECT_ROOT}/buildlog.txt"

    if [ -d "${PROJECT_ROOT}/output" ]; then
        sudo chown -R "$(id -u):$(id -g)" "${PROJECT_ROOT}/output" 2>/dev/null || sudo chmod -R 777 "${PROJECT_ROOT}/output" 2>/dev/null || true
    fi
}

run_test_qemu() {
    local iso="${PROJECT_ROOT}/output/${ISO_OUTPUT_NAME}"
    if [ ! -f "${iso}" ]; then
        echo "ERROR: ISO not found at ${iso}! Build the ISO first."
        exit 1
    fi

    # Ensure a sparse test disk exists for installer verification (takes ~0KB initially)
    local test_disk="${PROJECT_ROOT}/output/test-disk.qcow2"
    mkdir -p "${PROJECT_ROOT}/output"
    if [ ! -f "${test_disk}" ]; then
        echo "Creating 25GB sparse virtual test disk for installation testing..."
        qemu-img create -f qcow2 "${test_disk}" 25G
    fi

    local disk_arg=()
    if [ -f "${test_disk}" ]; then
        disk_arg=(-drive "file=${test_disk},format=qcow2,if=virtio")
    fi

    echo "Launching QEMU Virtual Machine test run (with Internet, Audio & 25GB Virtual Disk)..."
    qemu-system-x86_64 \
        -enable-kvm \
        -m 4G \
        -smp 4 \
        -vga virtio \
        -audiodev none,id=snd0 \
        -device intel-hda \
        -device hda-duplex,audiodev=snd0 \
        -nic user,model=virtio-net-pci \
        "${disk_arg[@]}" \
        -cdrom "${iso}" \
        -boot d
}

clean_build() {
    echo "Cleaning build directory..."
    if [ -d "${PROJECT_ROOT}/build" ]; then
        # Ensure nothing is mounted before removing
        "${PROJECT_ROOT}/scripts/02_mount_chroot.sh" unmount "${PROJECT_ROOT}/build/chroot" 2>/dev/null || true
        sudo rm -rf "${PROJECT_ROOT}/build"
        echo "Build directory cleaned."
    else
        echo "Build directory is already clean."
    fi
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --docker)
            MODE="docker"
            shift
            ;;
        --host)
            MODE="host"
            shift
            ;;
        --inner)
            MODE="inner"
            shift
            ;;
        --clean)
            clean_build
            exit 0
            ;;
        --test)
            run_test_qemu
            exit 0
            ;;
        --stage)
            TARGET_STAGE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --docker       Run build inside isolated Docker container (Recommended on Fedora)"
            echo "  --host         Run build directly on host machine (Requires root/sudo)"
            echo "  --stage <0-8>  Run only a specific stage"
            echo "  --clean        Clean temporary build artifacts"
            echo "  --test         Launch generated ISO in QEMU"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_banner

# Auto-detect host OS
if [ "${MODE}" = "auto" ]; then
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [ "${ID}" != "ubuntu" ] && [ "${ID}" != "debian" ]; then
            echo "Detected non-Debian host (${NAME}). Defaulting to isolated Docker container build."
            MODE="docker"
        else
            MODE="host"
        fi
    else
        MODE="docker"
    fi
fi

if [ "${MODE}" = "docker" ]; then
    run_docker_build
    exit 0
fi

# Root check for host build
if [ "${EUID}" -ne 0 ]; then
    echo "Host builds require root permissions to manage chroots and filesystem mounts."
    echo "Re-running with sudo..."
    exec sudo bash "$0" --host "$@"
fi

# Execute Pipeline Stages
run_stages() {
    case "${TARGET_STAGE}" in
        all)
            "${PROJECT_ROOT}/scripts/00_init_env.sh"
            "${PROJECT_ROOT}/scripts/01_bootstrap.sh"
            "${PROJECT_ROOT}/scripts/03_install_packages.sh"
            "${PROJECT_ROOT}/scripts/04_configure_system.sh"
            "${PROJECT_ROOT}/scripts/05_install_calamares.sh"
            "${PROJECT_ROOT}/scripts/06_cleanup_rootfs.sh"
            "${PROJECT_ROOT}/scripts/07_build_squashfs.sh"
            "${PROJECT_ROOT}/scripts/08_build_iso.sh"
            ;;
        0|00) "${PROJECT_ROOT}/scripts/00_init_env.sh" ;;
        1|01) "${PROJECT_ROOT}/scripts/01_bootstrap.sh" ;;
        3|03) "${PROJECT_ROOT}/scripts/03_install_packages.sh" ;;
        4|04) "${PROJECT_ROOT}/scripts/04_configure_system.sh" ;;
        5|05) "${PROJECT_ROOT}/scripts/05_install_calamares.sh" ;;
        6|06) "${PROJECT_ROOT}/scripts/06_cleanup_rootfs.sh" ;;
        7|07) "${PROJECT_ROOT}/scripts/07_build_squashfs.sh" ;;
        8|08) "${PROJECT_ROOT}/scripts/08_build_iso.sh" ;;
        *)
            echo "Unknown stage: ${TARGET_STAGE}"
            exit 1
            ;;
    esac
}

run_stages

echo ""
echo "=== Krubuntu Build Complete! ==="
echo "Output files located in: ${PROJECT_ROOT}/output/"
