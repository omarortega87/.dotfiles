#!/usr/bin/env bash

# Install NVIDIA proprietary drivers on Fedora (GNOME)
# Auto-selects the legacy R580 driver for Maxwell/Pascal/Volta GPUs
# (GTX 900/1000, TITAN V) since current NVIDIA branches dropped them.
# Usage: sudo ./nvidia-driver-install.sh [--with-cuda] [--yes] [--no-reboot]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ASSUME_YES=false
INSTALL_CUDA=false
AUTO_REBOOT=true
LEGACY_DRIVER=false

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step(){ echo -e "${CYAN}==>${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

confirm() {
    local prompt="$1"
    if $ASSUME_YES; then
        return 0
    fi
    read -r -p "$prompt [y/N] " answer
    [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

handle_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --with-cuda)  INSTALL_CUDA=true ;;
            --yes|-y)     ASSUME_YES=true ;;
            --no-reboot)  AUTO_REBOOT=false ;;
            -h|--help)
                echo "Usage: $0 [--with-cuda] [--yes] [--no-reboot]"
                echo "Auto-selects legacy 580xx driver for Maxwell/Pascal/Volta GPUs"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
}

detect_nvidia() {
    if ! lspci 2>/dev/null | grep -qi "nvidia"; then
        log_error "No NVIDIA GPU detected on this system"
        exit 1
    fi
    log_info "NVIDIA GPU detected:"
    lspci | grep -i nvidia

    # Maxwell/Pascal/Volta GPUs are no longer supported by the current
    # NVIDIA driver branch (R590+). Detect them by chip codename in lspci:
    #   GM10x/GM20x (Maxwell), GP10x (Pascal), GV100 (Volta)  -> legacy R580
    # Everything else (Turing TUxxx / Ampere GAxxx / Ada ADxxx / ...) -> current
    if lspci | grep -im1 -E "vga|3d" | grep -i nvidia | grep -qiE "\b(GM10[0-9]|GM20[0-9]|GP10[0-9]|GV10[0-9])M?\b"; then
        LEGACY_DRIVER=true
        log_warn "Detected a Maxwell/Pascal/Volta GPU. NVIDIA dropped support for these"
        log_warn "architectures after the R580 branch, so the ${YELLOW}legacy 580xx${NC} driver will be installed."
    else
        log_info "GPU uses a supported architecture - installing the ${GREEN}latest${NC} driver branch."
    fi
}

is_installed() {
    rpm -q "$1" &>/dev/null
}

secure_boot_enabled() {
    [[ -x /usr/bin/mokutil ]] && [[ "$(mokutil --sb-state 2>/dev/null)" == *"enabled"* ]]
}

enable_rpmfusion() {
    log_step "Enabling RPM Fusion repositories..."
    if is_installed rpmfusion-free-release && is_installed rpmfusion-nonfree-release; then
        log_info "RPM Fusion already enabled"
        return
    fi

    log_info "Updating package index..."
    dnf $([ $ASSUME_YES = true ] && echo -y) upgrade --refresh
    dnf $([ $ASSUME_YES = true ] && echo -y) install \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
}

branch_suffix() {
    $LEGACY_DRIVER && echo "-580xx" || echo ""
}

installed_branch() {
    if rpm -q xorg-x11-drv-nvidia-580xx &>/dev/null; then
        echo "legacy"
    elif rpm -q xorg-x11-drv-nvidia &>/dev/null; then
        echo "current"
    else
        echo "none"
    fi
}

switch_branch() {
    local current installed
    current=$($LEGACY_DRIVER && echo "legacy" || echo "current")
    installed=$(installed_branch)
    if [[ "$installed" == "none" || "$installed" == "$current" ]]; then
        return
    fi

    log_warn "Switching NVIDIA driver branch from '$installed' to '$current'..."
    log_warn "Removing previously installed NVIDIA driver packages..."
    local pkgs=() pkg
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && pkgs+=("$pkg")
    done < <(rpm -qa | grep -E '^(akmod-nvidia|xorg-x11-drv-nvidia|kmod-nvidia|nvidia-settings|nvidia-persistenced|nvidia-modprobe|nvidia-powerd)' | grep -v 'nvidia-gpu-firmware' || true)
    if ((${#pkgs[@]} > 0)); then
        dnf $([ $ASSUME_YES = true ] && echo -y) remove "${pkgs[@]}"
    fi
}

install_driver() {
    log_step "Installing NVIDIA driver packages..."
    switch_branch

    local suffix
    suffix=$(branch_suffix)
    if $LEGACY_DRIVER; then
        log_info "Using legacy R580 driver branch (akmod-nvidia-580xx)"
    fi

    if is_installed "akmod-nvidia${suffix}"; then
        log_info "akmod-nvidia${suffix} already installed"
    fi

    dnf $([ $ASSUME_YES = true ] && echo -y) install "akmod-nvidia${suffix}" "xorg-x11-drv-nvidia${suffix}-cuda"

    log_info "Installing 32-bit compatibility libraries (for gaming)..."
    dnf $([ $ASSUME_YES = true ] && echo -y) install "xorg-x11-drv-nvidia${suffix}-libs.i686" || true

    log_info "Installing kernel build dependencies..."
    dnf $([ $ASSUME_YES = true ] && echo -y) install kernel-devel-matched kernel-headers gcc make
}

set_kms_param() {
    log_step "Configuring nvidia-drm.modeset=1 (required for GNOME Wayland)..."
    local cmdline="/proc/cmdline"
    if [[ -f "$cmdline" ]] && grep -q "nvidia-drm.modeset=1" "$cmdline"; then
        log_info "Kernel parameter already set"
        return
    fi
    if [[ ! -f /etc/kernel/cmdline ]]; then
        touch /etc/kernel/cmdline
    fi
    if ! grep -q "nvidia-drm.modeset=1" /etc/kernel/cmdline; then
        echo -n "nvidia-drm.modeset=1 " >> /etc/kernel/cmdline
        log_info "Added nvidia-drm.modeset=1 to /etc/kernel/cmdline"
    fi
    if command -v grub2-mkconfig &>/dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null || true
    fi
}

build_module() {
    log_step "Building NVIDIA kernel module..."
    akmods --force
    depmod -a

    if modinfo nvidia >/dev/null 2>&1; then
        log_info "NVIDIA module built: $(modinfo -F version nvidia)"
    else
        log_error "NVIDIA module not found after build"
    fi

    log_step "Regenerating initramfs so the NVIDIA module is loaded at boot..."
    dracut --force --regenerate-all
}

handle_secure_boot() {
    if ! secure_boot_enabled; then
        log_info "Secure Boot is disabled - MOK enrollment not needed"
        return
    fi

    log_warn "Secure Boot is enabled. The NVIDIA module must be signed or MOK enrolled."
    if confirm "Enroll the akmods signing key now? (requires reboot to complete)"; then
        dnf $([ $ASSUME_YES = true ] && echo -y) install mokutil || true
        if [[ -f /etc/pki/akmods/certs/public_key.der ]]; then
            mokutil --import /etc/pki/akmods/certs/public_key.der
            log_info "MOK key imported. Enroll it on next reboot (choose 'Enroll MOK')."
        else
            log_warn "MOK cert not found at /etc/pki/akmods/certs/public_key.der"
        fi
    else
        log_warn "Skipping MOK enrollment. Driver may not load."
    fi
}

install_cuda_toolkit() {
    log_step "Installing CUDA toolkit..."
    dnf $([ $ASSUME_YES = true ] && echo -y) install cuda-toolkit
}

verify_installation() {
    log_step "Verifying installation..."
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
        nvidia-smi
        log_info "NVIDIA driver is working"
    else
        log_warn "nvidia-smi not working yet - this is expected until after reboot"
    fi
    if command -v nvcc >/dev/null 2>&1; then
        nvcc --version | tail -n 1
    fi
}

main() {
    handle_args "$@"
    check_root
    detect_nvidia
    enable_rpmfusion
    install_driver
    set_kms_param
    build_module
    handle_secure_boot

    if $INSTALL_CUDA; then
        install_cuda_toolkit
    fi

    verify_installation

    log_step "Done."
    if $AUTO_REBOOT && confirm "Reboot now to load the NVIDIA driver?"; then
        reboot
    else
        log_info "Reboot when ready: sudo reboot"
    fi
}

main "$@"