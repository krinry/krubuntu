#!/bin/bash
# Krubuntu Build Engine - 02_mount_chroot.sh
# Virtual filesystem mounting and safe unmounting engine.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

mount_virtual_fs() {
    local target="$1"
    echo "Mounting virtual filesystems in: ${target}"

    mkdir -p "${target}/dev" "${target}/dev/pts" "${target}/proc" "${target}/sys" "${target}/run"

    mountpoint -q "${target}/dev"     || mount --bind /dev "${target}/dev"
    mountpoint -q "${target}/dev/pts" || mount --bind /dev/pts "${target}/dev/pts"
    mountpoint -q "${target}/proc"    || mount -t proc proc "${target}/proc"
    mountpoint -q "${target}/sys"     || mount -t sysfs sysfs "${target}/sys"
    mountpoint -q "${target}/run"     || mount --bind /run "${target}/run"

    # Ensure DNS resolv.conf is functional inside chroot during build operations
    rm -f "${target}/etc/resolv.conf" 2>/dev/null || true
    if [ -f /etc/resolv.conf ]; then
        cp -L /etc/resolv.conf "${target}/etc/resolv.conf" 2>/dev/null || true
    else
        echo "nameserver 1.1.1.1" > "${target}/etc/resolv.conf"
        echo "nameserver 8.8.8.8" >> "${target}/etc/resolv.conf"
    fi
}

unmount_virtual_fs() {
    local target="$1"
    echo "Safely unmounting virtual filesystems in: ${target}"

    # Lazy unmount in reverse dependency order
    for mount_pt in "${target}/dev/pts" "${target}/proc" "${target}/sys" "${target}/run" "${target}/dev"; do
        if mountpoint -q "${mount_pt}"; then
            umount -lf "${mount_pt}" 2>/dev/null || true
        fi
    done

    # Verify no leaks
    local leaks
    leaks=$(mount | grep "${target}" || true)
    if [ -n "${leaks}" ]; then
        echo "WARNING: Remaining mounts detected:"
        echo "${leaks}"
        echo "Forcing secondary lazy unmount..."
        umount -lf "${target}/dev/pts" "${target}/proc" "${target}/sys" "${target}/run" "${target}/dev" 2>/dev/null || true
    else
        echo "All virtual mounts cleaned up cleanly."
    fi
}

run_in_chroot() {
    local target="$1"
    shift
    local cmd="$*"

    mount_virtual_fs "${target}"
    trap 'unmount_virtual_fs "'"${target}"'"' EXIT INT TERM

    echo "Executing in chroot: ${cmd}"
    chroot "${target}" /bin/bash -c "${cmd}"

    unmount_virtual_fs "${target}"
    trap - EXIT INT TERM
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ACTION="${1:-}"
    TARGET="${2:-${PROJECT_ROOT}/build/chroot}"

    case "${ACTION}" in
        mount)
            mount_virtual_fs "${TARGET}"
            ;;
        unmount|umount)
            unmount_virtual_fs "${TARGET}"
            ;;
        exec)
            shift 2
            run_in_chroot "${TARGET}" "$@"
            ;;
        *)
            echo "Usage: $0 [mount|unmount|exec] [chroot_dir] [command]"
            exit 1
            ;;
    esac
fi
