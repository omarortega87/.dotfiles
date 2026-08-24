#!/bin/bash

# NVIDIA GPU Toggle Script for Fedora
# Usage: nvidia-toggle {enable|disable|status|install}

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_status(){ echo -e "${CYAN}[STATUS]${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

get_nvidia_pci() {
    lspci | grep -i nvidia | head -1 | awk '{print $1}'
}

get_gpu_status() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    if [[ -z "$pci_id" ]]; then
        log_error "No NVIDIA GPU detected"
        exit 1
    fi

    local power_path="/sys/bus/pci/devices/0000:${pci_id}/power/runtime_status"
    if [[ -f "$power_path" ]]; then
        local status
        status=$(cat "$power_path")
        echo "$status"
    else
        echo "unknown"
    fi
}

is_nvidia_loaded() {
    lsmod | grep -q nvidia
}

has_bbswitch() {
    [[ -d /proc/acpi/bbswitch ]] 2>/dev/null
}

disable_nvidia_bbswitch() {
    log_info "Disabling NVIDIA GPU via bbswitch..."
    echo OFF > /proc/acpi/bbswitch
    if [[ $? -eq 0 ]]; then
        log_info "NVIDIA GPU disabled successfully"
    else
        log_error "Failed to disable NVIDIA GPU"
        exit 1
    fi
}

enable_nvidia_bbswitch() {
    log_info "Enabling NVIDIA GPU via bbswitch..."
    echo ON > /proc/acpi/bbswitch
    if [[ $? -eq 0 ]]; then
        log_info "NVIDIA GPU enabled successfully"
    else
        log_error "Failed to enable NVIDIA GPU"
        exit 1
    fi
}

unbind_nvidia() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    local driver_path="/sys/bus/pci/devices/0000:${pci_id}/driver"
    
    if [[ -L "$driver_path" ]]; then
        local current_driver
        current_driver=$(basename "$(readlink "$driver_path")")
        log_info "Current driver: $current_driver"
        
        if [[ "$current_driver" == "nvidia" || "$current_driver" == "nouveau" ]]; then
            log_info "Unbinding from driver..."
            echo "0000:${pci_id}" > /sys/bus/pci/devices/0000:${pci_id}/unbind 2>/dev/null || true
            
            log_info "Binding to pci-stub..."
            echo "0000:${pci_id}" > /sys/bus/pci/drivers/pci-stub/bind 2>/dev/null || true
            
            log_info "NVIDIA GPU unbound"
        fi
    fi
}

bind_nvidia() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    
    log_info "Unbinding from pci-stub..."
    echo "0000:${pci_id}" > /sys/bus/pci/devices/0000:${pci_id}/unbind 2>/dev/null || true
    
    log_info "Binding to nvidia driver..."
    echo "0000:${pci_id}" > /sys/bus/pci/drivers/nvidia/bind 2>/dev/null || true
    
    log_info "NVIDIA GPU bound to nvidia driver"
}

disable_nvidia_pm() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    local pm_path="/sys/bus/pci/devices/0000:${pci_id}/power/control"
    
    if [[ -f "$pm_path" ]]; then
        log_info "Setting NVIDIA GPU to auto power management..."
        echo "auto" > "$pm_path"
        log_info "NVIDIA GPU power management set to auto (will power down when idle)"
    fi
}

enable_nvidia_pm() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    local pm_path="/sys/bus/pci/devices/0000:${pci_id}/power/control"
    
    if [[ -f "$pm_path" ]]; then
        log_info "Setting NVIDIA GPU to on..."
        echo "on" > "$pm_path"
        log_info "NVIDIA GPU power management set to on"
    fi
}

unload_nvidia_modules() {
    if is_nvidia_loaded; then
        log_info "Unloading NVIDIA kernel modules..."
        modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia 2>/dev/null || true
        log_info "NVIDIA modules unloaded"
    else
        log_warn "NVIDIA modules not loaded"
    fi
}

load_nvidia_modules() {
    if ! is_nvidia_loaded; then
        log_info "Loading NVIDIA kernel modules..."
        modprobe nvidia 2>/dev/null || true
        modprobe nvidia_uvm 2>/dev/null || true
        modprobe nvidia_modeset 2>/dev/null || true
        modprobe nvidia_drm 2>/dev/null || true
        log_info "NVIDIA modules loaded"
    else
        log_warn "NVIDIA modules already loaded"
    fi
}

disable_nvidia() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    
    if [[ -z "$pci_id" ]]; then
        log_error "No NVIDIA GPU detected"
        exit 1
    fi
    
    log_info "Disabling NVIDIA GPU (${pci_id})..."
    
    if has_bbswitch; then
        disable_nvidia_bbswitch
    else
        unload_nvidia_modules
        unbind_nvidia
        disable_nvidia_pm
    fi
    
    log_info "NVIDIA GPU disabled"
    log_info "Run '$0 status' to verify"
}

enable_nvidia() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    
    if [[ -z "$pci_id" ]]; then
        log_error "No NVIDIA GPU detected"
        exit 1
    fi
    
    log_info "Enabling NVIDIA GPU (${pci_id})..."
    
    if has_bbswitch; then
        enable_nvidia_bbswitch
    else
        bind_nvidia
        enable_nvidia_pm
        load_nvidia_modules
    fi
    
    log_info "NVIDIA GPU enabled"
    log_info "Run '$0 status' to verify"
}

show_status() {
    local pci_id
    pci_id=$(get_nvidia_pci)
    
    echo ""
    echo "=========================================="
    echo "        NVIDIA GPU Status"
    echo "=========================================="
    
    if [[ -z "$pci_id" ]]; then
        log_error "No NVIDIA GPU detected"
        exit 1
    fi
    
    log_status "PCI ID: ${pci_id}"
    
    local gpu_status
    gpu_status=$(get_gpu_status)
    
    case "$gpu_status" in
        active)
            log_status "Power State: ${GREEN}ACTIVE${NC}"
            ;;
        suspended)
            log_status "Power State: ${YELLOW}SUSPENDED${NC}"
            ;;
        *)
            log_status "Power State: ${RED}UNKNOWN${NC}"
            ;;
    esac
    
    if is_nvidia_loaded; then
        log_status "Driver: ${GREEN}Loaded${NC}"
    else
        log_status "Driver: ${RED}Not Loaded${NC}"
    fi
    
    if has_bbswitch; then
        local bbswitch_state
        bbswitch_state=$(cat /proc/acpi/bbswitch)
        log_status "bbswitch: ${bbswitch_state}"
    fi
    
    local pm_path="/sys/bus/pci/devices/0000:${pci_id}/power/control"
    if [[ -f "$pm_path" ]]; then
        local pm_state
        pm_state=$(cat "$pm_path")
        log_status "Power Management: ${pm_state}"
    fi
    
    echo "=========================================="
    echo ""
}

install_bbswitch() {
    log_info "Installing bbswitch for NVIDIA GPU switching..."
    
    if has_bbswitch; then
        log_warn "bbswitch is already installed and loaded"
        return 0
    fi
    
    log_info "Installing bbswitch via dnf..."
    dnf install -y akmod-bbswitch
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to install bbswitch"
        log_info "Try: sudo dnf install akmod-bbswitch"
        exit 1
    fi
    
    log_info "Loading bbswitch module..."
    modprobe bbswitch
    
    if [[ $? -ne 0 ]]; then
        log_warn "Could not load bbswitch now - may need reboot"
    fi
    
    log_info "Enabling bbswitch on boot..."
    echo "bbswitch" > /etc/modules-load.d/bbswitch.conf 2>/dev/null || true
    
    log_info "bbswitch installed successfully"
    log_info "You may need to reboot for changes to take effect"
}

show_usage() {
    echo ""
    echo "NVIDIA GPU Toggle Script for Fedora"
    echo ""
    echo "Usage: $0 {enable|disable|status|install}"
    echo ""
    echo "Commands:"
    echo "  install  - Install bbswitch package for GPU switching"
    echo "  enable   - Enable NVIDIA GPU"
    echo "  disable  - Disable NVIDIA GPU (save power)"
    echo "  status   - Show NVIDIA GPU status"
    echo ""
    echo "Examples:"
    echo "  sudo $0 install"
    echo "  sudo $0 enable"
    echo "  sudo $0 disable"
    echo "  sudo $0 status"
    echo ""
    echo "Notes:"
    echo "  - Requires root privileges (sudo)"
    echo "  - Run 'install' first to set up bbswitch"
    echo "  - Works with bbswitch or power management"
    echo "  - For hybrid graphics (Optimus/PRIME)"
    echo ""
}

main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    check_root
    
    case "$1" in
        -h|--help|help)
            show_usage
            ;;
        install)
            install_bbswitch
            ;;
        enable)
            enable_nvidia
            ;;
        disable)
            disable_nvidia
            ;;
        status)
            show_status
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"