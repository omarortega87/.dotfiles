#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# ── Hyprland + Wayland full setup for Arch Linux ──
# Run on a fresh Arch install. Installs everything needed for the
# waybar/hyprland config in this repo and sets up symlinks so changes
# are tracked by git.
# Usage: ./install.sh

DOTDIR="$HOME/.dotfiles"
CONFIG_SRC="$DOTDIR/arch-hyprland/setup-hyprland/configs"

# ── Packages ──────────────────────────────────────────────────────────────────
HYPRLAND_PKGS=(
  hyprland hyprlauncher hyprcursor hyprlang
  wayland wayland-protocols xorg-xwayland
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils
)

TERMINAL_PKGS=(ghostty ghostty-shell-integration ghostty-terminfo)

AUDIO_PKGS=(
  pipewire pipewire-audio pipewire-pulse pipewire-alsa pipewire-jack
  wireplumber libpipewire libpulse libwireplumber
  gst-plugin-pipewire
  pavucontrol pamixer
  playerctl
)

NETWORK_PKGS=(
  networkmanager network-manager-applet nm-connection-editor
  wpa_supplicant
)

BLUETOOTH_PKGS=(bluez bluez-utils bluez-libs bluez-obex)

VIDEO_PKGS=(
  nvidia-open nvidia-settings nvidia-utils
  libva
)

FM_PKGS=(
  dolphin
  gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-gphoto2 gvfs-mtp gvfs-nfs
  gvfs-onedrive gvfs-smb gvfs-wsdd
)

INTEL_PKGS=(
  intel-ucode thermald lm_sensors
  intel-gmmlib intel-media-driver libva-intel-driver vulkan-intel
  linux-firmware-intel iio-sensor-proxy
)

MISC_PKGS=(
  polkit power-profiles-daemon brightnessctl gnome-keyring
  grim slurp libnotify
  wl-clipboard foot
  adwaita-fonts noto-fonts noto-fonts-emoji fontconfig
  tmux
)

PACKAGES=(
  "${HYPRLAND_PKGS[@]}"
  "${TERMINAL_PKGS[@]}"
  "${AUDIO_PKGS[@]}"
  "${NETWORK_PKGS[@]}"
  "${BLUETOOTH_PKGS[@]}"
  "${INTEL_PKGS[@]}"
  "${VIDEO_PKGS[@]}"
  "${FM_PKGS[@]}"
  "${MISC_PKGS[@]}"
)

echo ":: Installing packages..."
sudo pacman -Syu --noconfirm "${PACKAGES[@]}"

# ── AUR packages (via yay) ─────────────────────────────────────────────────────
echo ":: Installing AUR helper (yay-bin)..."
if ! command -v yay &>/dev/null; then
  TMPDIR=$(mktemp -d)
  sudo pacman -S --noconfirm --needed base-devel git
  git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin"
  (cd "$TMPDIR/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$TMPDIR"
fi

echo ":: Installing AUR packages..."
yay -S --noconfirm libva-nvidia-driver-git bluetui awww

# ── NVIDIA GPU setup ──────────────────────────────────────────────────────────
echo ":: Configuring NVIDIA modules..."
if ! grep -q 'nvidia nvidia_modeset' /etc/mkinitcpio.conf 2>/dev/null; then
  sudo sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
fi

if ! grep -q 'nvidia_drm.modeset=1' /etc/kernel/cmdline 2>/dev/null; then
  echo " nvidia_drm.modeset=1" | sudo tee -a /etc/kernel/cmdline > /dev/null
fi

echo ":: Rebuilding initramfs..."
sudo mkinitcpio -P

# ── Intel / fan control setup ──────────────────────────────────────────────────
echo ":: Configuring Intel sensors..."
if [ ! -f /etc/sysconfig/lm_sensors ]; then
  echo "  → Running sensors-detect (safe defaults)..."
  sudo sensors-detect --auto > /dev/null 2>&1 || true
fi

if [ ! -f /etc/fancontrol ]; then
  echo ""
  echo "  ⚠ Fan control requires manual setup:"
  echo "    1. sudo pwmconfig           # walks you through each fan"
  echo "    2. sudo systemctl enable --now fancontrol"
  echo ""
fi

# ── Config symlinks ───────────────────────────────────────────────────────────
# Symlink instead of rsync so live edits are tracked by the dotfiles repo.
echo ":: Setting up config symlinks..."

link_config() {
  local src="$1"
  local dest="$2"
  local dest_parent
  dest_parent=$(dirname "$dest")

  mkdir -p "$dest_parent"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    echo "  → symlink already correct: $dest"
    return
  fi

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  → backing up existing: $dest → ${dest}.bak"
    mv "$dest" "${dest}.bak"
  elif [ -L "$dest" ]; then
    rm "$dest"
  fi

  ln -s "$src" "$dest"
  echo "  → symlinked $dest → $src"
}

for item in "$CONFIG_SRC/.config/"*; do
  name=$(basename "$item")
  link_config "$item" "$HOME/.config/$name"
done

for item in "$CONFIG_SRC/.local/bin/"*; do
  name=$(basename "$item")
  link_config "$item" "$HOME/.local/bin/$name"
done

# ── Make scripts executable ───────────────────────────────────────────────────
chmod +x "$HOME/.config/waybar/power-profile.sh" 2>/dev/null || true
chmod +x "$HOME/.config/waybar/system-stats.sh" 2>/dev/null || true
chmod +x "$HOME/.local/bin/powerprofiles-init"
chmod +x "$HOME/.local/bin/battery-monitor"
chmod +x "$HOME/.local/bin/screenshot"

# ── Fonts (JetBrainsMono Nerd Font) ───────────────────────────────────────────
mkdir -p "$HOME/.local/share/fonts"

if [ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf" ]; then
  echo ":: Downloading JetBrainsMono Nerd Font..."
  TMPDIR=$(mktemp -d)
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip" \
    -o "$TMPDIR/JetBrainsMono.zip"
  unzip -q "$TMPDIR/JetBrainsMono.zip" -d "$TMPDIR/fonts"
  cp "$TMPDIR/fonts/"*.ttf "$HOME/.local/share/fonts/"
  rm -rf "$TMPDIR"
  fc-cache -f
  echo "  → JetBrainsMono Nerd Font installed"
else
  echo "  → JetBrainsMono Nerd Font already present"
fi

# ── System services ───────────────────────────────────────────────────────────
echo ":: Enabling system services..."
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl unmask power-profiles-daemon.service 2>/dev/null || true
sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl enable --now gdm.service

# ── Sudoers: passwordless platform-profile switching for Waybar ───────────────
if [ ! -f /etc/sudoers.d/waybar-power-profile ]; then
  echo ":: Setting up sudoers rule for power profile switching..."
  echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/firmware/acpi/platform_profile" | \
    sudo tee /etc/sudoers.d/waybar-power-profile > /dev/null
  sudo chmod 440 /etc/sudoers.d/waybar-power-profile
fi

# ── User services ─────────────────────────────────────────────────────────────
echo ":: Enabling user services..."
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service
systemctl --user enable --now omarchy-battery-monitor.timer

# ── Flatpak Firefox ───────────────────────────────────────────────────────────
if ! flatpak list 2>/dev/null | grep -q org.mozilla.firefox; then
  echo ":: Installing Firefox via flatpak..."
  flatpak install -y flathub org.mozilla.firefox
fi

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo ":: Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✔ Setup complete! Reboot to apply NVIDIA settings, then select 'Hyprland' from GDM."
echo "  Config files are symlinked to $DOTDIR — edit ~/.config/hypr/ or ~/.config/waybar/"
echo "  and changes are tracked by git automatically."
