-- Wayland env vars
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

-- Nvidia env vars
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GL_GSYNC_ALLOWED", "0")
hl.env("__GL_VRR_ALLOWED", "0")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
hl.env("NVD_BACKEND", "direct")

-- Autostart
local wallpaper = os.getenv("HOME") .. "/Pictures/wallpaper.jpg"

hl.on("hyprland.start", function ()
  hl.exec_cmd("waybar")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("~/.local/bin/powerprofiles-init")
  hl.exec_cmd("awww img " .. wallpaper)
  hl.exec_cmd("bash -c 'sleep 4 && hyprctl dispatch dpms off && sleep 0.5 && hyprctl dispatch dpms on'")
end)
