#!/bin/bash
set -euo pipefail

echo "==> Adding NVIDIA modules to mkinitcpio..."
sudo sed -i 's/^MODULES=()$/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

echo "==> Adding nvidia_drm.modeset=1 to kernel cmdline..."
sudo sed -i 's/$/ nvidia_drm.modeset=1/' /etc/kernel/cmdline

echo "==> Installing NVIDIA drivers..."
sudo pacman -S --needed nvidia-open nvidia-settings

echo "==> Rebuilding UKI initramfs..."
sudo mkinitcpio -p linux

echo "==> Done! Reboot to apply."
echo "    Run: sudo reboot"
