#!/usr/bin/env bash
# playwright-arch-setup -- Install Playwright + all Arch Linux system dependencies
#
# Playwright's `install-deps` only supports Debian/Ubuntu.
# This script installs the equivalent Arch packages (pacman), downloads compat
# libraries from Ubuntu 24.04 where needed, and patches WebKit wrappers so all
# 3 browser engines work correctly on Arch.
#
# Differences vs Fedora:
#   - Arch's libjpeg-turbo is built WITH_JPEG8=ON, so libjpeg.so.8 ships
#     natively (no Ubuntu download needed unless it's missing).
#   - Arch still ships newer ICU than WebKit expects, so ICU 74 compat libs
#     from Ubuntu are downloaded into the compat dir.
#   - gst-libav IS in official repos (no RPM-Fusion-style workaround).
#   - Single libdir (/usr/lib), no multilib paths.
#
# Usage:
#   ./setup.sh              # Full setup (deps + compat libs + browsers + verify)
#   ./setup.sh --deps-only  # Only install system deps + download compat libs
#   ./setup.sh --browsers   # Only install/update browsers + patch wrappers
#   ./setup.sh --patch      # Only patch WebKit wrappers (after manual browser install)
#   ./setup.sh --check      # Verify everything works
#   ./setup.sh --install    # Install pw wrapper + setup script to ~/.local
#   ./setup.sh --ci         # Non-interactive mode (no color, no TTY checks)
#   ./setup.sh --help

set -euo pipefail

# ── Config ─────────────────────────────────────────────────────
COMPAT_DIR="${PLAYWRIGHT_COMPAT_DIR:-$HOME/.local/lib/playwright-compat}"
BROWSER_DIR="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
CI_MODE=false
MODE="full"
PACMAN_LOG=""
SKIPPED_PKGS=()
INSTALLED_PKGS=()
VERSION_FILE="$COMPAT_DIR/.pw-version"

# ── Colors (initialized empty, set by setup_colors) ────────────
RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''

# ── Ubuntu mirror list for compat library downloads ────────────
# Multiple mirrors for resilience against archive removal
UBUNTU_MIRRORS=(
    "https://archive.ubuntu.com/ubuntu"
    "https://mirrors.kernel.org/ubuntu"
    "https://mirror.cs.uchicago.edu/ubuntu"
    "https://mirrors.mit.edu/ubuntu"
)

# ── Cleanup trap ───────────────────────────────────────────────
TMPDIRS=()
cleanup() {
    for d in "${TMPDIRS[@]}"; do
        [ -d "$d" ] && rm -rf "$d"
    done
}
trap cleanup EXIT

# ── Colors ─────────────────────────────────────────────────────
setup_colors() {
    if [ "$CI_MODE" = true ] || [ ! -t 1 ]; then
        RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
    else
        RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
        BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
    fi
}

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }
die()   { err "$@"; exit 1; }

# ── Architecture detection ────────────────────────────────────
# Returns "arch:libdir" for Ubuntu .deb packages
deb_arch() {
    case "$(uname -m)" in
        aarch64) echo "arm64:usr/lib/aarch64-linux-gnu" ;;
        *)       echo "amd64:usr/lib/x86_64-linux-gnu" ;;
    esac
}

# ── Version tracking ──────────────────────────────────────────
get_installed_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo ""
    fi
}

save_installed_version() {
    local version="$1"
    mkdir -p "$(dirname "$VERSION_FILE")"
    echo "$version" > "$VERSION_FILE"
}

get_current_playwright_version() {
    if command -v npx &>/dev/null; then
        npx playwright --version 2>/dev/null | sed 's/^Version: //' || echo ""
    else
        echo ""
    fi
}

print_version_info() {
    local installed_version
    local current_version
    installed_version=$(get_installed_version)
    current_version=$(get_current_playwright_version)

    if [ -n "$installed_version" ]; then
        info "Last configured version: $installed_version"
    else
        info "No previous version recorded (first run)"
    fi

    if [ -n "$current_version" ]; then
        info "Current Playwright:     $current_version"
    else
        info "Current Playwright:     not installed"
    fi
}

# ── Temp dir helper ────────────────────────────────────────────
make_temp() {
    local prefix="${1:-playwright}"
    local dir="/tmp/${prefix}-$$-$(date +%s)"
    mkdir -p "$dir"
    TMPDIRS+=("$dir")
    echo "$dir"
}

# ── Download .deb with mirror fallback ─────────────────────────
# Usage: download_deb <output_dir> <filename> <pool_path> <version1> [version2 ...]
# Tries each version against each mirror, returns 0 on first success
download_deb() {
    local output_dir="$1"
    local filename="$2"
    local pool_path="$3"
    shift 3
    local versions=("$@")
    local arch
    arch=$(deb_arch | cut -d: -f1)

    mkdir -p "$output_dir"

    for mirror in "${UBUNTU_MIRRORS[@]}"; do
        for ver in "${versions[@]}"; do
            local url="${mirror}/pool/${pool_path}/${filename}_${ver}_${arch}.deb"
            if curl -fsSL --connect-timeout 10 --max-time 120 -o "${output_dir}/${filename}.deb" "$url" 2>/dev/null; then
                # Verify it's actually a .deb (older `file` says "ar archive",
                # newer versions say "Debian binary package")
                if file "${output_dir}/${filename}.deb" 2>/dev/null | grep -qE "ar archive|Debian binary package"; then
                    return 0
                fi
                rm -f "${output_dir}/${filename}.deb"
            fi
        done
    done
    return 1
}

# ── Extract .deb and find data.tar ─────────────────────────────
# Usage: extract_deb <deb_file> <output_dir>
# Extracts only the lib directory from the .deb
extract_deb() {
    local deb_file="$1"
    local extract_dir="$2"
    local lib_dir
    lib_dir=$(deb_arch | cut -d: -f2)

    mkdir -p "$extract_dir"
    pushd "$extract_dir" >/dev/null

    if ! ar x "$deb_file" 2>/dev/null; then
        popd >/dev/null; return 1
    fi

    # Find data.tar in priority order
    local data_tar=""
    for f in data.tar.zst data.tar.xz data.tar.gz; do
        if [ -f "$f" ]; then
            data_tar="$f"
            break
        fi
    done
    if [ -z "$data_tar" ]; then
        popd >/dev/null; return 1
    fi

    local tar_flags=""
    case "$data_tar" in
        *.zst) tar_flags="--zstd" ;;
        *.xz)  tar_flags="-J" ;;
        *.gz)  tar_flags="-z" ;;
    esac
    # shellcheck disable=SC2086
    tar $tar_flags -xf "$data_tar" "./${lib_dir}/" 2>/dev/null || true
    popd >/dev/null

    [ -d "${extract_dir}/${lib_dir}" ]
}

# ── Parse arguments ────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --deps-only|deps-only|deps)     MODE="deps" ;;
        --browsers|browsers)            MODE="browsers" ;;
        --patch|patch)                  MODE="patch" ;;
        --check|check)                  MODE="check" ;;
        --install|install)              MODE="install" ;;
        --update|update)                MODE="update" ;;
        --update-compat|update-compat)  MODE="update-compat" ;;
        --ci|ci)                        CI_MODE=true ;;
        --help|-h|help)
            cat <<'EOF'
Usage: setup.sh [OPTIONS]

Options:
  (no args)        Full setup: system deps + compat libs + browsers + verify
  --deps-only      Only install system deps + download compat libs
  --browsers       Only install/update Playwright browsers + patch wrappers
  --patch          Only patch WebKit wrappers (after npx playwright install)
  --check          Verify installation (launch each browser engine)
  --install        Install pw wrapper + setup script to ~/.local/bin
  --update         Update Playwright + browsers (auto-detects version changes)
  --update-compat  Force re-download of compat libraries (ICU)
  --ci             Non-interactive mode (no color, suitable for Docker/CI)
  --help           Show this message

  All flags can be used with or without -- prefix (e.g., install or --install)

Environment:
  PLAYWRIGHT_COMPAT_DIR    Override compat lib location (default: ~/.local/lib/playwright-compat)
  PLAYWRIGHT_BROWSERS_PATH Override browser cache location (default: ~/.cache/ms-playwright)
EOF
            exit 0
            ;;
        *) die "Unknown argument: $arg (try --help)" ;;
    esac
done

setup_colors

# ── Verify Arch ────────────────────────────────────────────────
verify_arch() {
    if [ ! -f /etc/os-release ]; then
        die "Cannot detect OS (no /etc/os-release)"
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    case "$ID" in
        arch|omarchy) ;;
        manjaro|artix|endeavouros|cachyos)
            warn "Detected $ID (Arch-derived). Package names may differ slightly."
            ;;
        *)
            die "This script is for Arch Linux (detected: $ID)"
            ;;
    esac
    info "Detected ${PRETTY_NAME:-Arch Linux}"
    if ! command -v pacman &>/dev/null; then
        die "pacman not found"
    fi
}

# ── Check sudo availability ───────────────────────────────────
check_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    if ! sudo -n true 2>/dev/null; then
        warn "This script needs sudo. You may be prompted for your password."
        if ! sudo -v 2>/dev/null; then
            die "Cannot obtain sudo privileges"
        fi
    fi
}

# ── Run pacman with proper error handling ──────────────────────
run_pacman() {
    local pacman_output
    local pacman_exit

    if [ "$(id -u)" -eq 0 ]; then
        pacman_output=$(pacman "$@" 2>&1) || pacman_exit=$?
    else
        pacman_output=$(sudo pacman "$@" 2>&1) || pacman_exit=$?
    fi

    pacman_exit=${pacman_exit:-0}

    PACMAN_LOG="$pacman_output"

    if [ "$pacman_exit" -ne 0 ]; then
        err "pacman failed (exit code: $pacman_exit)"
        echo "$pacman_output" | tail -20 >&2
        return "$pacman_exit"
    fi

    return 0
}

# ── Validate package exists in repos ──────────────────────────
validate_packages() {
    SKIPPED_PKGS=()
    local valid=()
    for pkg in "$@"; do
        # pacman -Si returns 0 if package exists in any configured repo
        if pacman -Si "$pkg" &>/dev/null; then
            valid+=("$pkg")
        else
            SKIPPED_PKGS+=("$pkg")
        fi
    done

    REPO_PKGS=("${valid[@]}")

    if [ "${#SKIPPED_PKGS[@]}" -gt 0 ]; then
        warn "Package(s) not found in repos (will be skipped): ${SKIPPED_PKGS[*]}"
    fi
}

# ── Print package install summary ──────────────────────────────
print_pkg_summary() {
    echo ""
    info "Package install summary:"
    if [ "${#INSTALLED_PKGS[@]}" -gt 0 ]; then
        ok "Installed: ${#INSTALLED_PKGS[@]} packages"
    fi
    if [ "${#SKIPPED_PKGS[@]}" -gt 0 ]; then
        warn "Skipped (not in repos): ${SKIPPED_PKGS[*]}"
        echo ""
        echo "  Some skipped packages may be available from the AUR:"
        echo "    paru -S ${SKIPPED_PKGS[*]}      # or: yay -S ${SKIPPED_PKGS[*]}"
    fi
}

# ── Install system dependencies ────────────────────────────────
install_deps() {
    info "Installing Playwright system dependencies..."

    check_sudo

    # --- Tools (needed for downloading/extracting compat libraries) ---
    local tool_deps=(
        curl binutils zstd file tar findutils
    )

    # --- Chromium / Chrome for Testing ---
    local chromium_deps=(
        nss nspr atk at-spi2-core libcups libdrm
        libxcomposite libxdamage libxrandr mesa
        pango cairo alsa-lib alsa-plugins libxkbcommon
        libxfixes libxext libx11 libxcb libxi libxtst libxss
        dbus expat libxshmfence
    )

    # --- Firefox ---
    local firefox_deps=(
        gtk3 dbus-glib
    )

    # --- WebKit ---
    # Note: gst-libav IS in official Arch repos (unlike Fedora).
    # hyphen/flite may only exist in the AUR and will be skipped gracefully.
    local webkit_deps=(
        gstreamer gst-plugins-base
        gst-plugins-good gst-plugins-bad gst-libav
        libsoup3 libgcrypt enchant libsecret
        hyphen libmanette openjpeg2 woff2
        harfbuzz libwebp lcms2 libjxl
        libavif wayland mesa flite
    )

    # --- General / shared ---
    local general_deps=(
        noto-fonts ttf-liberation ttf-dejavu
        fontconfig freetype libpng libjpeg-turbo
        libxml2 libxslt zlib
    )

    local all_deps=(
        "${tool_deps[@]}"
        "${chromium_deps[@]}"
        "${firefox_deps[@]}"
        "${webkit_deps[@]}"
        "${general_deps[@]}"
    )

    # Refresh pacman metadata first
    info "Refreshing package databases..."
    run_pacman -Sy --noconfirm || warn "Failed to refresh databases, continuing anyway"

    # Validate packages exist before attempting install (pacman aborts on unknown targets)
    info "Validating package availability..."
    validate_packages "${all_deps[@]}"

    # Install with --needed so already-installed packages are untouched
    if [ "${#REPO_PKGS[@]}" -gt 0 ]; then
        info "Installing ${#REPO_PKGS[@]} packages..."
        if ! run_pacman -S --needed --noconfirm "${REPO_PKGS[@]}"; then
            warn "Some packages may have failed to install (see above)"
        fi
    fi

    # Check which packages actually got installed
    INSTALLED_PKGS=()
    for pkg in "${REPO_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            INSTALLED_PKGS+=("$pkg")
        fi
    done

    # Verify critical tools are available (may come from outside pacman, e.g. nvm)
    local critical_tools=(curl ar tar zstd file)
    local not_installed=()
    for tool in "${critical_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            not_installed+=("$tool")
        fi
    done

    if [ "${#not_installed[@]}" -gt 0 ]; then
        die "Critical tools failed to install: ${not_installed[*]}"
    fi

    print_pkg_summary
    ok "System dependencies installed"

    if ! command -v node &>/dev/null; then
        warn "Node.js not found. Install with: sudo pacman -S nodejs npm (or use nvm/bun)"
    fi

    # Install compat libs for WebKit
    install_webkit_compat
}

# ── Install WebKit compat libraries ───────────────────────────
install_webkit_compat() {
    info "Installing WebKit compatibility libraries..."

    # --- libjpeg with JPEG8 ABI ---
    # Unlike Fedora, Arch builds libjpeg-turbo WITH_JPEG8=ON, providing
    # libjpeg.so.8 with LIBJPEG_8.0 symbols natively. Only fall back to the
    # Ubuntu package if the system doesn't provide it.
    ensure_libjpeg_compat

    # --- libjxl soname symlinks ---
    # Playwright's WebKit may request an older libjxl soname than Arch ships.
    mkdir -p "$COMPAT_DIR"
    local candidate system_libjxl
    system_libjxl=$(find /usr/lib -maxdepth 1 -name 'libjxl.so.0.*' -not -type l 2>/dev/null | sort -V | tail -1)
    if [ -n "$system_libjxl" ]; then
        for candidate in libjxl.so.0.8 libjxl.so.0.9 libjxl.so.0.10; do
            if [ ! -e "/usr/lib/$candidate" ] && [ ! -e "$COMPAT_DIR/$candidate" ]; then
                ln -sf "$system_libjxl" "$COMPAT_DIR/$candidate"
                ok "Created compat symlink: $candidate -> $(basename "$system_libjxl")"
            fi
        done
    fi

    # --- ICU compat libraries ---
    # Playwright's WebKit is built on Ubuntu 24.04 (ICU 74). Arch ships newer
    # ICU versions (75+) which are NOT ABI-compatible. We extract Ubuntu's
    # libicu74 package into the compat directory.
    install_icu_compat

    # --- libxml2 / flite compat libraries ---
    # Arch bumped libxml2 to soname .so.16 and its flite package omits several
    # voice sublibs WebKit links against. Extract both from Ubuntu.
    install_extra_compat_libs
}

install_extra_compat_libs() {
    # --- libxml2.so.2 ---
    if [ ! -f "$COMPAT_DIR/libxml2.so.2" ] && [ ! -f /usr/lib/libxml2.so.2 ]; then
        info "Installing libxml2.so.2 compat library..."
        local tmp_dir
        tmp_dir=$(make_temp "playwright-libxml2-compat")
        if download_deb "$tmp_dir" "libxml2" "main/libx/libxml2" \
            "2.9.14+dfsg-1.3ubuntu3.8" "2.9.14+dfsg-1.3ubuntu3"; then
            local lib_dir
            lib_dir=$(deb_arch | cut -d: -f2)
            if extract_deb "$tmp_dir/libxml2.deb" "$tmp_dir"; then
                cp -a "$tmp_dir/$lib_dir"/libxml2.so.2* "$COMPAT_DIR/" 2>/dev/null || true
                [ -f "$COMPAT_DIR/libxml2.so.2" ] \
                    && ok "Installed libxml2.so.2 -> $COMPAT_DIR/" \
                    || warn "libxml2 extraction produced no library"
            else
                warn "Could not extract libxml2 from .deb package"
            fi
        else
            warn "Could not download libxml2 from any mirror. WebKit may not work."
        fi
    fi

    # --- flite voice sublibs ---
    # Arch's flite build omits cmu_grapheme/time_awb/us_awb/us_rms voices.
    if [ ! -f "$COMPAT_DIR/libflite_cmu_us_awb.so.1" ] && [ ! -f /usr/lib/libflite_cmu_us_awb.so.1 ]; then
        info "Installing flite voice compatibility libraries..."
        local tmp_dir
        tmp_dir=$(make_temp "playwright-flite-compat")
        if download_deb "$tmp_dir" "libflite1" "main/f/flite" \
            "2.2-2" "2.0.0-release-1"; then
            local lib_dir
            lib_dir=$(deb_arch | cut -d: -f2)
            if extract_deb "$tmp_dir/libflite1.deb" "$tmp_dir"; then
                cp -a "$tmp_dir/$lib_dir"/libflite*.so* "$COMPAT_DIR/" 2>/dev/null || true
                [ -f "$COMPAT_DIR/libflite_cmu_us_awb.so.1" ] \
                    && ok "Installed flite voice libs -> $COMPAT_DIR/" \
                    || warn "flite extraction produced no voice libraries"
            else
                warn "Could not extract flite from .deb package"
            fi
        else
            warn "Could not download libflite1 from any mirror. WebKit may not work."
        fi
    fi
}

ensure_libjpeg_compat() {
    if [ -f /usr/lib/libjpeg.so.8 ]; then
        ok "System libjpeg.so.8 present (JPEG8 ABI built in)"
        return
    fi

    # Verify existing compat copy has the right symbol version
    if [ -f "$COMPAT_DIR/libjpeg.so.8" ]; then
        local existing_sym
        existing_sym=$(objdump -p "$COMPAT_DIR/libjpeg.so.8" 2>/dev/null | grep -o 'LIBJPEG_8.0' || true)
        if [ "$existing_sym" = "LIBJPEG_8.0" ]; then
            ok "Compat libjpeg (LIBJPEG_8.0) already installed"
            return
        fi
    fi

    download_compat_libjpeg
}

download_compat_libjpeg() {
    info "Installing libjpeg with JPEG8 ABI (LIBJPEG_8.0 symbols)..."

    local tmp_dir
    tmp_dir=$(make_temp "playwright-libjpeg-compat")
    mkdir -p "$COMPAT_DIR"

    # Download Ubuntu 24.04's libjpeg-turbo8 package with mirror fallback
    if ! download_deb "$tmp_dir" "libjpeg-turbo8" "main/libj/libjpeg-turbo" \
        "2.1.5-2ubuntu2" "2.1.5-2ubuntu1" "2.1.5-2build1"; then
        warn "Could not download libjpeg-turbo8 package from any mirror. WebKit may not work."
        warn "Check your network connection or try again later."
        return
    fi

    # Extract and install
    local lib_dir
    lib_dir=$(deb_arch | cut -d: -f2)
    if extract_deb "$tmp_dir/libjpeg-turbo8.deb" "$tmp_dir"; then
        local extracted="$tmp_dir/$lib_dir"
        cp -a "$extracted"/libjpeg.so.8* "$COMPAT_DIR/" 2>/dev/null || true
        # Create libjpeg.so.8 symlink if only the versioned file was copied
        if [ ! -e "$COMPAT_DIR/libjpeg.so.8" ]; then
            local versioned=""
            for f in "$COMPAT_DIR"/libjpeg.so.8.*; do
                [ -f "$f" ] && versioned="$f" && break
            done
            if [ -n "$versioned" ]; then
                ln -sf "$(basename "$versioned")" "$COMPAT_DIR/libjpeg.so.8"
            fi
        fi
        ok "Installed compat libjpeg -> $COMPAT_DIR/"
    else
        warn "Could not extract libjpeg from .deb package"
    fi
}

install_icu_compat() {
    local icu_dir="$COMPAT_DIR/icu"
    if [ -f "$icu_dir/libicudata.so.74" ]; then
        ok "ICU 74 compat libs already installed"
        return
    fi

    # Check if system ICU is already 74 (no compat needed)
    if [ -f /usr/lib/libicudata.so.74 ]; then
        ok "System ICU is version 74 (no compat needed)"
        return
    fi

    info "Installing ICU 74 compat libraries for WebKit..."

    local tmp_dir
    tmp_dir=$(make_temp "playwright-icu-compat")
    mkdir -p "$icu_dir"

    # Download libicu74 from Ubuntu 24.04 (noble) with mirror fallback
    # Try multiple package versions since Ubuntu updates revisions
    if ! download_deb "$tmp_dir" "libicu74" "main/i/icu" \
        "74.2-1ubuntu3" "74.2-1ubuntu4" "74.2-1ubuntu3.1"; then
        warn "Could not download ICU 74 package from any mirror. WebKit may not work."
        warn "Check your network connection or try again later."
        return
    fi

    # Extract and install
    local lib_dir
    lib_dir=$(deb_arch | cut -d: -f2)
    if extract_deb "$tmp_dir/libicu74.deb" "$tmp_dir"; then
        local extracted="$tmp_dir/$lib_dir"
        cp -a "$extracted"/libicu*.so.74* "$icu_dir/" 2>/dev/null || true
        local count
        count=$(find "$icu_dir" -name 'libicu*.so.74*' -type f 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            ok "Installed $count ICU 74 compat libraries -> $icu_dir/"
        else
            warn "ICU 74 extraction produced no libraries"
        fi
    else
        warn "Could not extract ICU 74 libraries from deb package"
    fi
}

# ── Patch WebKit MiniBrowser wrappers ──────────────────────────
# Strategy: replace each MiniBrowser launcher script with a generated wrapper
# that mirrors the original's env-var setup (WEBKIT_EXEC_PATH, injected bundle,
# ...) but PREPENDS our compat library paths, then execs the real ELF binary
# directly. We must not chain-exec the original script: it unconditionally
# does `export LD_LIBRARY_PATH=...`, wiping the compat paths.
patch_webkit_wrappers() {
    local patched=0

    # Scan both default and custom browser paths
    local search_dirs=("$BROWSER_DIR")
    # Also check PLAYWRIGHT_BROWSERS_PATH if different
    if [ "$BROWSER_DIR" != "$HOME/.cache/ms-playwright" ] && [ -d "$HOME/.cache/ms-playwright" ]; then
        search_dirs+=("$HOME/.cache/ms-playwright")
    fi

    for base_dir in "${search_dirs[@]}"; do
        [ -d "$base_dir" ] || continue
        for webkit_dir in "$base_dir"/webkit-*/; do
            [ -d "$webkit_dir" ] || continue
            for wrapper in "$webkit_dir"minibrowser-{gtk,wpe}/MiniBrowser; do
                [ -f "$wrapper" ] || continue

                # Up to date?
                if grep -q 'playwright-compat-wrapper v2' "$wrapper" 2>/dev/null; then
                    continue
                fi

                # The real ELF binary must exist next to the launcher
                [ -e "${wrapper%/*}/bin/MiniBrowser" ] || continue

                # Keep a pristine backup of the original launcher
                local orig="${wrapper}.orig"
                if [ ! -f "$orig" ] && ! grep -q 'playwright-compat-wrapper' "$wrapper" 2>/dev/null; then
                    cp "$wrapper" "$orig"
                fi

                cat > "$wrapper" <<WRAPPER_EOF
#!/usr/bin/env bash
# playwright-compat-wrapper v2: Auto-generated by playwright-arch-setup
# Mirrors MiniBrowser.orig's env setup but keeps compat library paths on
# LD_LIBRARY_PATH, then launches the real binary directly.

MYDIR="\$(dirname "\$(readlink -f "\${BASH_SOURCE[0]}")")"
export WEBKIT_EXEC_PATH="\$MYDIR/bin"
export WEBKIT_INJECTED_BUNDLE_PATH="\$MYDIR/lib"
export WEBKIT_INSPECTOR_RESOURCES_PATH="\$MYDIR/share"
export LD_LIBRARY_PATH="\${HOME}/.local/lib/playwright-compat:\${HOME}/.local/lib/playwright-compat/icu:\$MYDIR/lib:\$MYDIR/sys/lib:\${LD_LIBRARY_PATH:-}"
exec "\$MYDIR/bin/MiniBrowser" "\$@"
WRAPPER_EOF
                chmod +x "$wrapper"
                patched=$((patched + 1))
            done
        done
    done

    if [ "$patched" -gt 0 ]; then
        ok "Patched $patched WebKit MiniBrowser wrapper(s) (v2)"
    else
        ok "WebKit wrappers already patched (or not yet installed)"
    fi
}

# ── Install Playwright npm package ─────────────────────────────
install_playwright_npm() {
    if ! command -v node &>/dev/null; then
        die "Node.js not found. Install with: sudo pacman -S nodejs npm (or use nvm/bun)"
    fi

    local force_update="${1:-false}"

    # Detect if playwright is already available
    if [ "$force_update" = false ] && npx playwright --version &>/dev/null 2>&1; then
        local ver
        ver=$(npx playwright --version 2>/dev/null || echo "unknown")
        ok "Playwright already available (v${ver})"
    else
        if [ "$force_update" = true ]; then
            info "Updating Playwright to latest version..."
        else
            info "Installing Playwright..."
        fi
        if command -v bun &>/dev/null; then
            bun install -g playwright @playwright/test
        elif command -v pnpm &>/dev/null; then
            pnpm add -g playwright @playwright/test
        else
            npm install -g playwright @playwright/test
        fi
        ok "Playwright installed/updated"
    fi
}

# ── Install browsers ───────────────────────────────────────────
install_browsers() {
    info "Installing Playwright browsers (Chromium, Firefox, WebKit)..."
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1 npx --yes playwright install chromium firefox webkit 2>&1
    ok "All browsers installed"

    # Auto-patch WebKit wrappers
    patch_webkit_wrappers

    if [ -d "$BROWSER_DIR" ]; then
        info "Browser cache: $BROWSER_DIR"
        du -sh "$BROWSER_DIR" 2>/dev/null | awk '{print "  Total size: " $1}'
    fi
}

# ── Check / verify ─────────────────────────────────────────────
check_installation() {
    # Run in subshell to avoid leaking LD_LIBRARY_PATH and env vars
    (
    info "Verifying Playwright installation..."
    echo ""

    export LD_LIBRARY_PATH="${COMPAT_DIR}:${COMPAT_DIR}/icu:${LD_LIBRARY_PATH:-/usr/lib}"
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1

    # Ensure Node.js can find globally installed playwright modules
    if command -v npm &>/dev/null; then
        export NODE_PATH="$(npm root -g 2>/dev/null):${NODE_PATH:-}"
    fi
    if command -v pnpm &>/dev/null; then
        export NODE_PATH="$(pnpm root -g 2>/dev/null):${NODE_PATH:-}"
    fi
    # bun: check common locations
    if [ -d "$HOME/.bun/install/global/node_modules" ]; then
        export NODE_PATH="$HOME/.bun/install/global/node_modules:${NODE_PATH:-}"
    fi

    # mise-managed npm tools (e.g. `mise use -g npm:playwright`)
    local mise_installs="${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs"
    if [ -d "$mise_installs" ]; then
        local pw_tool pw_core nm_dir
        while IFS= read -r pw_tool; do
            while IFS= read -r pw_core; do
                nm_dir=$(dirname "$pw_core")
                export NODE_PATH="$nm_dir:${NODE_PATH:-}"
            done < <(find "$pw_tool" -type d -name 'playwright-core' 2>/dev/null)
        done < <(find "$mise_installs" -maxdepth 2 -mindepth 1 -type d -name '*playwright*' 2>/dev/null)
    fi

    # Version-manager node (nvm/asdf/mise-node): global root sits next to the binary
    if command -v node &>/dev/null; then
        local node_global_root
        node_global_root="$(dirname "$(dirname "$(readlink -f "$(command -v node)")")")/lib/node_modules"
        [ -d "$node_global_root" ] && export NODE_PATH="$node_global_root:${NODE_PATH:-}"
    fi

    local all_good=true

    if npx playwright --version &>/dev/null; then
        ok "playwright CLI: $(npx playwright --version 2>/dev/null)"
    else
        err "playwright CLI not found"
        all_good=false
    fi

    for browser in chromium firefox webkit; do
        if [ "$browser" = "webkit" ] && ! ls -d "$BROWSER_DIR/webkit-"* &>/dev/null 2>&1; then
            warn "webkit: not installed"
            continue
        fi

        # Try require('playwright'), then fallback to require('playwright-core')
        local test_script="
            (async () => {
                let pw;
                try { pw = require('playwright'); }
                catch { pw = require('playwright-core'); }
                const b = await pw.${browser}.launch({ headless: true });
                const page = await b.newPage();
                await page.setContent('<h1>ok</h1>');
                const text = await page.textContent('h1');
                if (text === 'ok') process.stdout.write('ok');
                await b.close();
            })().catch(e => { process.stderr.write(e.message.split('\n')[0]); process.exit(1); });
        "
        local result=""
        local logfile="/tmp/pw-check-${browser}-$$.log"
        if result=$(node -e "$test_script" 2>"$logfile") && [ "$result" = "ok" ]; then
            ok "$browser: launches and renders correctly"
        else
            err "$browser: failed to launch"
            if [ -s "$logfile" ]; then
                err "  $(head -1 "$logfile")"
            fi
            all_good=false
        fi
        rm -f "$logfile"
    done

    echo ""
    if $all_good; then
        echo -e "${GREEN}All checks passed. Playwright is ready on Arch Linux.${NC}"
    else
        echo -e "${RED}Some checks failed. Run: ./setup.sh${NC}"
        exit 1
    fi
    ) # end subshell
}

# ── Ensure ~/.local/bin is in PATH ─────────────────────────────
ensure_local_bin_in_path() {
    # Fish: add to fish_user_paths if not already there
    if command -v fish &>/dev/null; then
        local fish_config="$HOME/.config/fish/config.fish"
        mkdir -p "$(dirname "$fish_config")"
        if ! grep -q 'local/bin' "$fish_config" 2>/dev/null; then
            echo 'fish_add_path -g ~/.local/bin' >> "$fish_config"
        fi
    fi

    # Bash: add to .bashrc if not already in PATH
    local bashrc="$HOME/.bashrc"
    if [ -f "$bashrc" ] && ! grep -q 'local/bin.*PATH\|PATH.*local/bin' "$bashrc" 2>/dev/null; then
        cat >> "$bashrc" <<'EOF'

# Add ~/.local/bin to PATH
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"
EOF
    fi

    # Zsh: add to .zshrc if it exists and not already in PATH
    local zshrc="$HOME/.zshrc"
    if [ -f "$zshrc" ] && ! grep -q 'local/bin.*PATH\|PATH.*local/bin' "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'EOF'

# Add ~/.local/bin to PATH
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"
EOF
    fi

    ok "Ensured ~/.local/bin is in PATH"
}

# ── Embedded shell functions ───────────────────────────────────
# These are the shell functions that were previously in separate files.
# They are now embedded directly in this script for standalone operation.

PW_BASH_CONTENT='#!/usr/bin/env bash
# pw -- Playwright Arch Linux wrapper
# Source this file or add to your .bashrc / .zshrc

PW_COMPAT_DIR="${PLAYWRIGHT_COMPAT_DIR:-$HOME/.local/lib/playwright-compat}"

pw() {
    case "${1:-}" in
        env|ENV)
            echo "PLAYWRIGHT_COMPAT_DIR=$PW_COMPAT_DIR"
            echo "LD_LIBRARY_PATH=${PW_COMPAT_DIR}:${PW_COMPAT_DIR}/icu:${LD_LIBRARY_PATH:-}"
            ;;
        setup|SETUP)
            "${PW_COMPAT_DIR}/../../bin/playwright-arch-setup" "${@:2}"
            ;;
        *)
            # Set up compat library paths and run playwright
            export LD_LIBRARY_PATH="${PW_COMPAT_DIR}:${PW_COMPAT_DIR}/icu:${LD_LIBRARY_PATH:-}"
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
            npx playwright "$@"
            ;;
    esac
}

_pw_completions() {
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "install install-deps open show-trace screenshot pdf codegen env setup" -- "${COMP_WORDS[1]}"))
    fi
}
complete -F _pw_completions pw
'

PW_FISH_CONTENT='#!/usr/bin/env fish
# pw -- Playwright Arch Linux wrapper (Fish shell)

set -gx PW_COMPAT_DIR (string replace -r "/$" "" "$PLAYWRIGHT_COMPAT_DIR" 2>/dev/null; or echo "$HOME/.local/lib/playwright-compat")

function pw
    switch (count $argv); case 0
        echo "Usage: pw <command> [options]"
        echo "Commands: install, install-deps, open, show-trace, screenshot, pdf, codegen, env, setup"
        return 1
    end

    set -l cmd $argv[1]

    switch "$cmd"
        case env ENV
            echo "PLAYWRIGHT_COMPAT_DIR=$PW_COMPAT_DIR"
            echo "LD_LIBRARY_PATH=$PW_COMPAT_DIR:$PW_COMPAT_DIR/icu:$LD_LIBRARY_PATH"
        case setup SETUP
            "$PW_COMPAT_DIR/../../bin/playwright-arch-setup" $argv[2..-1]
        case '*'
            set -gx LD_LIBRARY_PATH "$PW_COMPAT_DIR:$PW_COMPAT_DIR/icu:$LD_LIBRARY_PATH"
            set -gx PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS 1
            npx playwright $argv
    end
end

# Completions
complete -c pw -f
complete -c pw -n "__fish_use_subcommand" -a "install" -d "Install browsers"
complete -c pw -n "__fish_use_subcommand" -a "install-deps" -d "Install system dependencies"
complete -c pw -n "__fish_use_subcommand" -a "open" -d "Open browser"
complete -c pw -n "__fish_use_subcommand" -a "show-trace" -d "Show trace"
complete -c pw -n "__fish_use_subcommand" -a "screenshot" -d "Take screenshot"
complete -c pw -n "__fish_use_subcommand" -a "pdf" -d "Generate PDF"
complete -c pw -n "__fish_use_subcommand" -a "codegen" -d "Code generation"
complete -c pw -n "__fish_use_subcommand" -a "env" -d "Show environment"
complete -c pw -n "__fish_use_subcommand" -a "setup" -d "Run Arch setup"
'

# ── Install wrapper scripts ────────────────────────────────────
install_wrappers() {
    info "Installing to ~/.local/bin and shell config..."

    mkdir -p "$HOME/.local/bin"

    # Copy setup script itself
    cp "${BASH_SOURCE[0]}" "$HOME/.local/bin/playwright-arch-setup"
    chmod +x "$HOME/.local/bin/playwright-arch-setup"
    ok "Installed playwright-arch-setup -> ~/.local/bin/"

    # Ensure ~/.local/bin is in PATH for all shells
    ensure_local_bin_in_path

    # Install fish function (embedded content)
    if command -v fish &>/dev/null; then
        mkdir -p "$HOME/.config/fish/functions"
        echo "$PW_FISH_CONTENT" > "$HOME/.config/fish/functions/pw.fish"
        ok "Installed pw.fish -> ~/.config/fish/functions/"
    fi

    # Install bash function (embedded content)
    local bashrc="$HOME/.bashrc"
    if [ -f "$bashrc" ]; then
        if ! grep -q 'playwright-arch' "$bashrc" 2>/dev/null; then
            cat >> "$bashrc" <<'BASHEOF'

# Playwright Arch Linux wrapper
if [ -f "$HOME/.local/share/playwright-arch/pw.bash" ]; then
    source "$HOME/.local/share/playwright-arch/pw.bash"
fi
BASHEOF
            mkdir -p "$HOME/.local/share/playwright-arch"
            echo "$PW_BASH_CONTENT" > "$HOME/.local/share/playwright-arch/pw.bash"
            ok "Installed pw.bash -> ~/.local/share/playwright-arch/"
        else
            ok "Bash integration already installed"
        fi
    fi

    # Install zsh function (uses same bash-compatible function)
    local zshrc="$HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        if ! grep -q 'playwright-arch' "$zshrc" 2>/dev/null; then
            cat >> "$zshrc" <<'ZSHEOF'

# Playwright Arch Linux wrapper
if [ -f "$HOME/.local/share/playwright-arch/pw.bash" ]; then
    source "$HOME/.local/share/playwright-arch/pw.bash"
fi
ZSHEOF
            ok "Added pw to ~/.zshrc"
        fi
    fi

    echo ""
    ok "Installation complete. Restart your shell or run: source ~/.bashrc"
}

# ── Update Playwright ─────────────────────────────────────────
update_playwright() {
    echo ""
    info "Checking for Playwright updates..."
    print_version_info
    echo ""

    local installed_version
    local current_version
    installed_version=$(get_installed_version)
    current_version=$(get_current_playwright_version)
    local needs_browser_update=false

    # Check if Playwright version changed
    if [ "$installed_version" != "$current_version" ] || [ -z "$installed_version" ]; then
        if [ -z "$installed_version" ]; then
            info "First run - will install everything"
        else
            info "Version changed: $installed_version -> $current_version"
        fi
        needs_browser_update=true
    else
        ok "Playwright version unchanged ($current_version)"
    fi

    # Check if browsers exist
    if [ ! -d "$BROWSER_DIR" ] || [ -z "$(ls -A "$BROWSER_DIR" 2>/dev/null)" ]; then
        info "No browsers found - will install"
        needs_browser_update=true
    fi

    # Update npm package if needed
    if [ "$needs_browser_update" = true ]; then
        install_playwright_npm true  # force update
    fi

    # Update compat libraries
    info "Checking compat libraries..."
    install_webkit_compat

    # Update browsers if needed
    if [ "$needs_browser_update" = true ]; then
        info "Updating browsers..."
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1 npx --yes playwright install chromium firefox webkit 2>&1
        patch_webkit_wrappers
    else
        ok "Browsers up to date"
    fi

    # Save current version
    local new_version
    new_version=$(get_current_playwright_version)
    if [ -n "$new_version" ]; then
        save_installed_version "$new_version"
        ok "Saved version: $new_version"
    fi

    # Show final status
    echo ""
    info "Update complete"
    if [ -d "$BROWSER_DIR" ]; then
        du -sh "$BROWSER_DIR" 2>/dev/null | awk '{print "  Browser cache: " $1}'
    fi
}

# ── Update compat libraries only ──────────────────────────────
update_compat_libs() {
    echo ""
    info "Updating compat libraries..."
    print_version_info
    echo ""

    # Force re-download by removing existing files
    info "Removing existing compat libraries..."
    rm -f "$COMPAT_DIR/libjpeg.so.8"* 2>/dev/null || true
    rm -f "$COMPAT_DIR/icu/libicu"* 2>/dev/null || true
    rm -f "$COMPAT_DIR"/libjxl.so.0.* 2>/dev/null || true
    rm -f "$COMPAT_DIR"/libxml2.so.2* 2>/dev/null || true
    rm -f "$COMPAT_DIR"/libflite*.so* 2>/dev/null || true

    # Re-install
    install_webkit_compat

    echo ""
    ok "Compat libraries updated"
}

# ── Main ───────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}Playwright Arch Linux Setup${NC}"
    echo ""

    case "$MODE" in
        full)
            verify_arch
            install_deps
            install_playwright_npm
            install_browsers
            # Save version after successful full install
            local ver
            ver=$(get_current_playwright_version)
            if [ -n "$ver" ]; then
                save_installed_version "$ver"
            fi
            if [ "$CI_MODE" = false ]; then
                echo ""
                check_installation
            else
                ok "CI mode: skipping browser launch verification (run tests separately)"
            fi
            ;;
        deps)
            verify_arch
            install_deps
            ;;
        browsers)
            install_browsers
            # Save version after browser install
            local ver
            ver=$(get_current_playwright_version)
            if [ -n "$ver" ]; then
                save_installed_version "$ver"
            fi
            ;;
        patch)
            patch_webkit_wrappers
            ;;
        check)
            check_installation
            ;;
        install)
            install_wrappers
            ;;
        update)
            verify_arch
            update_playwright
            if [ "$CI_MODE" = false ]; then
                echo ""
                check_installation
            fi
            ;;
        update-compat)
            verify_arch
            update_compat_libs
            ;;
    esac
}

main
