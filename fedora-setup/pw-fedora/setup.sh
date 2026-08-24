#!/usr/bin/env bash
# playwright-fedora-setup -- Install Playwright + all Fedora system dependencies
#
# Playwright's `install-deps` only supports Debian/Ubuntu.
# This script installs the equivalent Fedora packages, downloads compat
# libraries from Ubuntu 24.04, and patches WebKit wrappers so all 3 browser
# engines work correctly on Fedora.
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
DNF_LOG=""
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

needs_update() {
    local installed_version
    local current_version
    installed_version=$(get_installed_version)
    current_version=$(get_current_playwright_version)

    # If no version recorded, treat as needing update
    if [ -z "$installed_version" ]; then
        return 0
    fi

    # If versions differ, update needed
    if [ "$installed_version" != "$current_version" ]; then
        return 0
    fi

    return 1
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
# Usage: download_deb <filename> <pool_path> <version1> [version2 ...]
# Tries each version against each mirror, returns 0 on first success
download_deb() {
    local filename="$1"
    local pool_path="$2"
    shift 2
    local versions=("$@")
    local output_dir="${3:-.}"

    for mirror in "${UBUNTU_MIRRORS[@]}"; do
        for ver in "${versions[@]}"; do
            local url="${mirror}/pool/${pool_path}/${filename}_${ver}_$(deb_arch | cut -d: -f1).deb"
            if curl -fsSL --connect-timeout 10 --max-time 120 -o "${output_dir}/${filename}.deb" "$url" 2>/dev/null; then
                # Verify it's actually a .deb
                if file "${output_dir}/${filename}.deb" 2>/dev/null | grep -q "ar archive"; then
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
  --update-compat  Force re-download of compat libraries (ICU, libjpeg)
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

# ── Verify Fedora ──────────────────────────────────────────────
verify_fedora() {
    if [ ! -f /etc/os-release ]; then
        die "Cannot detect OS (no /etc/os-release)"
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ "$ID" != "fedora" ]; then
        die "This script is for Fedora (detected: $ID)"
    fi
    info "Detected Fedora $VERSION_ID"
    if [ "${VERSION_ID:-0}" -lt 39 ] 2>/dev/null; then
        warn "Fedora $VERSION_ID is older than the tested range (39-43). Things may not work."
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

# ── Run dnf with proper error handling ─────────────────────────
run_dnf() {
    local dnf_output
    local dnf_exit

    if [ "$(id -u)" -eq 0 ]; then
        dnf_output=$(dnf "$@" 2>&1) || dnf_exit=$?
    else
        dnf_output=$(sudo dnf "$@" 2>&1) || dnf_exit=$?
    fi

    dnf_exit=${dnf_exit:-0}

    # Store for potential later display
    DNF_LOG="$dnf_output"

    if [ "$dnf_exit" -ne 0 ]; then
        err "dnf failed (exit code: $dnf_exit)"
        echo "$dnf_output" | tail -20 >&2
        return "$dnf_exit"
    fi

    return 0
}

# ── Validate package exists in repos ──────────────────────────
validate_packages() {
    SKIPPED_PKGS=()
    for pkg in "$@"; do
        # dnf repoquery returns 0 if package exists in any repo
        if ! sudo dnf repoquery --quiet --resolve "$pkg" 2>/dev/null | grep -q .; then
            SKIPPED_PKGS+=("$pkg")
        fi
    done

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
        echo "  To install skipped packages, you may need to enable additional repos:"
        echo "    sudo dnf install -y fedora-workstation-repository    # for -free packages"
        echo "    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi
}

# ── Install system dependencies ────────────────────────────────
install_deps() {
    info "Installing Playwright system dependencies..."

    check_sudo

    # --- Tools (needed for downloading/extracting compat libraries) ---
    local tool_deps=(
        curl binutils zstd tar findutils
    )

    # --- Chromium / Chrome for Testing ---
    local chromium_deps=(
        nss nspr atk at-spi2-atk cups-libs libdrm
        libXcomposite libXdamage libXrandr mesa-libgbm
        pango cairo alsa-lib libxkbcommon
        libXfixes libXext libX11 libxcb
        dbus-libs expat libxshmfence
    )

    # --- Firefox ---
    local firefox_deps=(
        gtk3 dbus-glib
    )

    # --- WebKit ---
    # Note: gstreamer1-libav is NOT in Fedora repos (it's in RPM Fusion).
    # Use gstreamer1-plugins-ugly-free instead, or skip if unavailable.
    local webkit_deps=(
        gstreamer1 gstreamer1-plugins-base
        gstreamer1-plugins-good gstreamer1-plugins-bad-free
        gstreamer1-plugins-ugly-free
        libsoup3 libgcrypt enchant2 libsecret
        hyphen libmanette openjpeg2 woff2
        harfbuzz-icu libwebp lcms2 libjxl
        libatomic mesa-libEGL mesa-libGLES
        libwayland-server libavif flite
    )

    # --- General / shared ---
    local general_deps=(
        xorg-x11-fonts-Type1 xorg-x11-fonts-misc
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

    # Refresh dnf metadata first
    info "Refreshing package metadata..."
    run_dnf makecache --timer || warn "Failed to refresh metadata, continuing anyway"

    # Validate critical packages exist before attempting install
    info "Validating package availability..."
    validate_packages "${all_deps[@]}" || true

    # Install with --skip-unavailable and track results
    info "Installing ${#all_deps[@]} packages..."
    if ! run_dnf install -y --skip-unavailable "${all_deps[@]}"; then
        warn "Some packages may have failed to install (see above)"
    fi

    # Check which packages actually got installed
    INSTALLED_PKGS=()
    for pkg in "${all_deps[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            INSTALLED_PKGS+=("$pkg")
        fi
    done

    # Verify critical packages are actually installed
    local critical_pkgs=(curl binutils nodejs)
    local not_installed=()
    for pkg in "${critical_pkgs[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            not_installed+=("$pkg")
        fi
    done

    if [ "${#not_installed[@]}" -gt 0 ]; then
        die "Critical packages failed to install: ${not_installed[*]}"
    fi

    print_pkg_summary
    ok "System dependencies installed"

    # Install compat libs for WebKit
    install_webkit_compat
}

# ── Install WebKit compat libraries ───────────────────────────
install_webkit_compat() {
    info "Installing WebKit compatibility libraries..."

    # --- libjpeg-turbo with JPEG8 ABI ---
    # Fedora exports LIBJPEG_6.2 version symbols; Playwright's Ubuntu-built
    # WebKit expects LIBJPEG_8.0. We download Ubuntu's libjpeg-turbo8 package
    # which provides libjpeg.so.8 with the correct symbols.
    if [ -f "$COMPAT_DIR/lib64/libjpeg.so.8" ]; then
        local existing_sym
        existing_sym=$(objdump -p "$COMPAT_DIR/lib64/libjpeg.so.8" 2>/dev/null | grep -o 'LIBJPEG_8.0' || true)
        if [ "$existing_sym" = "LIBJPEG_8.0" ]; then
            ok "Compat libjpeg (LIBJPEG_8.0) already installed"
        else
            download_compat_libjpeg
        fi
    else
        download_compat_libjpeg
    fi

    # --- libjxl soversion symlink ---
    mkdir -p "$COMPAT_DIR"
    local system_libjxl
    # Sort by version to get the newest, pick the actual file (not symlinks)
    system_libjxl=$(find /usr/lib64 -name 'libjxl.so.0.*' -not -type l 2>/dev/null | sort -V | tail -1)
    if [ -n "$system_libjxl" ] && [ ! -e "$COMPAT_DIR/libjxl.so.0.8" ]; then
        ln -sf "$system_libjxl" "$COMPAT_DIR/libjxl.so.0.8"
        ok "Created compat symlink: libjxl.so.0.8 -> $(basename "$system_libjxl")"
    fi

    # --- ICU compat libraries ---
    # Playwright's WebKit is built on Ubuntu 24.04 (ICU 74). Fedora ships newer
    # ICU versions (75-77+) which are NOT ABI-compatible. We extract Ubuntu's
    # libicu74 package into the compat directory.
    install_icu_compat
}

install_icu_compat() {
    local icu_dir="$COMPAT_DIR/icu"
    if [ -f "$icu_dir/libicudata.so.74" ]; then
        ok "ICU 74 compat libs already installed"
        return
    fi

    # Check if system ICU is already 74 (no compat needed)
    if [ -f /usr/lib64/libicudata.so.74 ]; then
        ok "System ICU is version 74 (no compat needed)"
        return
    fi

    info "Installing ICU 74 compat libraries for WebKit..."

    local tmp_dir
    tmp_dir=$(make_temp "playwright-icu-compat")
    mkdir -p "$icu_dir"

    # Download libicu74 from Ubuntu 24.04 (noble) with mirror fallback
    # Try multiple package versions since Ubuntu updates revisions
    if ! download_deb "libicu74" "main/i/icu" \
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

download_compat_libjpeg() {
    info "Installing libjpeg with JPEG8 ABI (LIBJPEG_8.0 symbols)..."

    local tmp_dir
    tmp_dir=$(make_temp "playwright-libjpeg-compat")
    mkdir -p "$COMPAT_DIR/lib64"

    # Download Ubuntu 24.04's libjpeg-turbo8 package with mirror fallback
    if ! download_deb "libjpeg-turbo8" "main/libj/libjpeg-turbo" \
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
        cp -a "$extracted"/libjpeg.so.8* "$COMPAT_DIR/lib64/" 2>/dev/null || true
        # Create libjpeg.so.8 symlink if only the versioned file was copied
        if [ ! -e "$COMPAT_DIR/lib64/libjpeg.so.8" ]; then
            local versioned=""
            for f in "$COMPAT_DIR/lib64"/libjpeg.so.8.*; do
                [ -f "$f" ] && versioned="$f" && break
            done
            if [ -n "$versioned" ]; then
                ln -sf "$(basename "$versioned")" "$COMPAT_DIR/lib64/libjpeg.so.8"
            fi
        fi
        ok "Installed compat libjpeg -> $COMPAT_DIR/lib64/"
    else
        warn "Could not extract libjpeg from .deb package"
    fi
}

# ── Patch WebKit MiniBrowser wrappers ──────────────────────────
# Strategy: Instead of modifying the original MiniBrowser script, we create
# wrapper scripts that set up LD_LIBRARY_PATH and exec the original.
# This is more robust against Playwright updates.
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

                # If already a wrapper we created, skip
                if grep -q 'playwright-compat-wrapper' "$wrapper" 2>/dev/null; then
                    continue
                fi

                # If already patched with our LD_LIBRARY_PATH approach, skip
                if grep -q 'playwright-compat' "$wrapper" 2>/dev/null; then
                    continue
                fi

                # Only handle shell script wrappers (not ELF binaries)
                if ! head -1 "$wrapper" 2>/dev/null | grep -q '^#!'; then
                    continue
                fi

                # Check if it has an LD_LIBRARY_PATH export we can intercept
                if grep -q 'export LD_LIBRARY_PATH=' "$wrapper"; then
                    local orig="${wrapper}.orig"

                    # If we already have a backup, use that as source
                    if [ ! -f "$orig" ]; then
                        cp "$wrapper" "$orig"
                    fi

                    # Create wrapper script that sets our paths then execs original
                    cat > "$wrapper" <<WRAPPER_EOF
#!/usr/bin/env bash
# playwright-compat-wrapper: Auto-generated by playwright-fedora-setup
# Adds Fedora compat libraries to LD_LIBRARY_PATH before launching WebKit

export LD_LIBRARY_PATH="\${HOME}/.local/lib/playwright-compat/lib64:\${HOME}/.local/lib/playwright-compat/icu:\${HOME}/.local/lib/playwright-compat:\${LD_LIBRARY_PATH:-}"
exec "\${BASH_SOURCE[0]}.orig" "\$@"
WRAPPER_EOF
                    chmod +x "$wrapper"
                    patched=$((patched + 1))
                fi
            done
        done
    done

    if [ "$patched" -gt 0 ]; then
        ok "Patched $patched WebKit MiniBrowser wrapper(s) (created safe wrappers)"
    else
        ok "WebKit wrappers already patched (or not yet installed)"
    fi
}

# ── Install Playwright npm package ─────────────────────────────
install_playwright_npm() {
    if ! command -v node &>/dev/null; then
        die "Node.js not found. Install with: sudo dnf install nodejs"
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
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1 npx playwright install chromium firefox webkit 2>&1
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

    export LD_LIBRARY_PATH="${COMPAT_DIR}/lib64:${COMPAT_DIR}/icu:${COMPAT_DIR}:${LD_LIBRARY_PATH:-/usr/lib64}"
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
        echo -e "${GREEN}All checks passed. Playwright is ready on Fedora.${NC}"
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
# pw -- Playwright Fedora wrapper
# Source this file or add to your .bashrc / .zshrc

PW_COMPAT_DIR="${PLAYWRIGHT_COMPAT_DIR:-$HOME/.local/lib/playwright-compat}"

pw() {
    case "${1:-}" in
        env|ENV)
            echo "PLAYWRIGHT_COMPAT_DIR=$PW_COMPAT_DIR"
            echo "LD_LIBRARY_PATH=${PW_COMPAT_DIR}/lib64:${PW_COMPAT_DIR}/icu:${PW_COMPAT_DIR}:${LD_LIBRARY_PATH:-}"
            ;;
        setup|SETUP)
            "${PW_COMPAT_DIR}/../../bin/playwright-fedora-setup" "${@:2}"
            ;;
        *)
            # Set up compat library paths and run playwright
            export LD_LIBRARY_PATH="${PW_COMPAT_DIR}/lib64:${PW_COMPAT_DIR}/icu:${PW_COMPAT_DIR}:${LD_LIBRARY_PATH:-}"
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
# pw -- Playwright Fedora wrapper (Fish shell)

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
            echo "LD_LIBRARY_PATH=$PW_COMPAT_DIR/lib64:$PW_COMPAT_DIR/icu:$PW_COMPAT_DIR:$LD_LIBRARY_PATH"
        case setup SETUP
            "$PW_COMPAT_DIR/../../bin/playwright-fedora-setup" $argv[2..-1]
        case '*'
            set -gx LD_LIBRARY_PATH "$PW_COMPAT_DIR/lib64:$PW_COMPAT_DIR/icu:$PW_COMPAT_DIR:$LD_LIBRARY_PATH"
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
complete -c pw -n "__fish_use_subcommand" -a "setup" -d "Run Fedora setup"
'

# ── Install wrapper scripts ────────────────────────────────────
install_wrappers() {
    info "Installing to ~/.local/bin and shell config..."

    mkdir -p "$HOME/.local/bin"

    # Copy setup script itself
    cp "${BASH_SOURCE[0]}" "$HOME/.local/bin/playwright-fedora-setup"
    chmod +x "$HOME/.local/bin/playwright-fedora-setup"
    ok "Installed playwright-fedora-setup -> ~/.local/bin/"

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
        if ! grep -q 'playwright-fedora' "$bashrc" 2>/dev/null; then
            cat >> "$bashrc" <<'BASHEOF'

# Playwright Fedora wrapper (https://github.com/CybLow/playwright-fedora)
if [ -f "$HOME/.local/share/playwright-fedora/pw.bash" ]; then
    source "$HOME/.local/share/playwright-fedora/pw.bash"
fi
BASHEOF
            mkdir -p "$HOME/.local/share/playwright-fedora"
            echo "$PW_BASH_CONTENT" > "$HOME/.local/share/playwright-fedora/pw.bash"
            ok "Installed pw.bash -> ~/.local/share/playwright-fedora/"
        else
            ok "Bash integration already installed"
        fi
    fi

    # Install zsh function (uses same bash-compatible function)
    local zshrc="$HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        if ! grep -q 'playwright-fedora' "$zshrc" 2>/dev/null; then
            cat >> "$zshrc" <<'ZSHEOF'

# Playwright Fedora wrapper (https://github.com/CybLow/playwright-fedora)
if [ -f "$HOME/.local/share/playwright-fedora/pw.bash" ]; then
    source "$HOME/.local/share/playwright-fedora/pw.bash"
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
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1 npx playwright install chromium firefox webkit 2>&1
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
    rm -f "$COMPAT_DIR/lib64/libjpeg.so.8"* 2>/dev/null || true
    rm -f "$COMPAT_DIR/icu/libicu"* 2>/dev/null || true
    rm -f "$COMPAT_DIR/libjxl.so.0.8" 2>/dev/null || true

    # Re-install
    install_webkit_compat

    echo ""
    ok "Compat libraries updated"
}

# ── Main ───────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}Playwright Fedora Setup${NC}"
    echo ""

    case "$MODE" in
        full)
            verify_fedora
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
            verify_fedora
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
            verify_fedora
            update_playwright
            if [ "$CI_MODE" = false ]; then
                echo ""
                check_installation
            fi
            ;;
        update-compat)
            verify_fedora
            update_compat_libs
            ;;
    esac
}

main
