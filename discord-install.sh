#!/usr/bin/env bash
# Discord installer for Linux (official .tar.gz build, no root needed).
#
#   curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/discord-install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/discord-install.sh | bash -s -- --dir ~/Apps/Discord
#   curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/discord-install.sh | bash -s -- --uninstall
#
# Run it again any time to update. It remembers where Discord was installed.
# Note: Discord also updates itself after the first launch; this script only
# refreshes the launcher files and the menu entry.

set -euo pipefail

DOWNLOAD_URL="https://discord.com/api/download?platform=linux&format=tar.gz"
DEFAULT_DIR="$HOME/.local/share/Discord"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_FILE="$CONFIG_HOME/discord-installer/install-dir"
DESKTOP_FILE="$DATA_HOME/applications/discord.desktop"
BIN_LINK="$HOME/.local/bin/discord"

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: discord-install.sh [--dir PATH] [--force] [--uninstall [--purge]]

  --dir PATH   Install to PATH (default: $DEFAULT_DIR, or the saved location)
  --force      Reinstall even if already up to date
  --uninstall  Remove Discord's files, menu entry and command
  --purge      With --uninstall, also delete your Discord data in ~/.config/discord
EOF
}

dir="" force=0 uninstall=0 purge=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dir) [ $# -ge 2 ] || die "--dir needs a path"; dir="$2"; shift 2 ;;
        --dir=*) dir="${1#--dir=}"; shift ;;
        --force) force=1; shift ;;
        --uninstall) uninstall=1; shift ;;
        --purge) purge=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "unknown option: $1" ;;
    esac
done

[ "$(id -u)" -ne 0 ] || die "don't run this as root; it installs for your user only"
[ "$(uname -m)" = "x86_64" ] || die "Discord only ships Linux builds for x86_64"
for cmd in curl tar; do
    command -v "$cmd" >/dev/null || die "'$cmd' is required"
done

saved_dir=""
[ -f "$STATE_FILE" ] && saved_dir="$(cat "$STATE_FILE")"

# --- uninstall ----------------------------------------------------------------
if [ "$uninstall" -eq 1 ]; then
    target="${dir:-$saved_dir}"
    [ -n "$target" ] || die "no saved install found; pass --dir PATH"
    [ -f "$target/updater_bootstrap" ] || die "'$target' doesn't look like a Discord install"
    pkill -x Discord 2>/dev/null && sleep 1 || true
    rm -rf "$target"
    rm -f "$DESKTOP_FILE" "$STATE_FILE"
    [ -L "$BIN_LINK" ] && rm -f "$BIN_LINK"
    rmdir "$(dirname "$STATE_FILE")" 2>/dev/null || true
    if [ "$purge" -eq 1 ]; then
        rm -rf "$CONFIG_HOME/discord"
        info "Removed Discord and its data."
    else
        info "Removed Discord. Your data is still in $CONFIG_HOME/discord (use --purge to delete it)."
    fi
    command -v update-desktop-database >/dev/null && update-desktop-database -q "$DATA_HOME/applications" || true
    exit 0
fi

# --- pick install location ----------------------------------------------------
if [ -z "$dir" ]; then
    if [ -n "$saved_dir" ]; then
        dir="$saved_dir"
    elif { : </dev/tty; } 2>/dev/null; then
        # Works under "curl | bash" because we read from the terminal, not stdin.
        printf 'Install location [%s]: ' "$DEFAULT_DIR" >/dev/tty
        read -r dir </dev/tty || true
        dir="${dir:-$DEFAULT_DIR}"
    else
        dir="$DEFAULT_DIR"
    fi
fi
case "$dir" in "~"|"~/"*) dir="$HOME${dir#\~}" ;; esac
mkdir -p "$(dirname "$dir")"
dir="$(cd "$(dirname "$dir")" && pwd)/$(basename "$dir")"

if [ -e "$dir" ] && [ ! -f "$dir/updater_bootstrap" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
    die "'$dir' exists and isn't a Discord install; pick an empty or new folder"
fi

# --- check version ------------------------------------------------------------
info "Checking latest Discord version..."
real_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$DOWNLOAD_URL")" \
    || die "couldn't reach discord.com"
latest="$(printf '%s' "$real_url" | grep -oE '/[0-9]+\.[0-9]+\.[0-9]+/' | tr -d / || true)"
[ -n "$latest" ] || latest="unknown"
current="$(cat "$dir/.version" 2>/dev/null || true)"

if [ "$force" -eq 0 ] && [ "$latest" != "unknown" ] && [ "$current" = "$latest" ]; then
    info "Discord $current is already installed in $dir; refreshing menu entry only."
else
    # --- download & install ---------------------------------------------------
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    info "Downloading Discord $latest..."
    curl -fL --progress-bar -o "$tmp/discord.tar.gz" "$real_url" || die "download failed"
    tar -xzf "$tmp/discord.tar.gz" -C "$tmp" || die "couldn't extract the archive"
    [ -x "$tmp/Discord/updater_bootstrap" ] && [ -x "$tmp/Discord/discord" ] \
        || die "unexpected archive layout; Discord may have changed its package"

    # Swap the new files in place; keep the old copy until the swap succeeds.
    rm -f "$tmp/Discord/postinst.sh"   # meant for system packages (needs root)
    printf '%s\n' "$latest" > "$tmp/Discord/.version"
    if [ -d "$dir" ]; then
        mv "$dir" "$tmp/old"
    fi
    mv "$tmp/Discord" "$dir"
    info "Installed Discord $latest to $dir"
fi

# --- menu entry, command, saved location ---------------------------------------
mkdir -p "$(dirname "$DESKTOP_FILE")" "$(dirname "$BIN_LINK")" "$(dirname "$STATE_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec="$dir/discord" --url -- %u
Icon=$dir/discord.png
Type=Application
Categories=Network;InstantMessaging;
MimeType=x-scheme-handler/discord;
EOF
ln -sfn "$dir/discord" "$BIN_LINK"
printf '%s\n' "$dir" > "$STATE_FILE"
command -v update-desktop-database >/dev/null && update-desktop-database -q "$DATA_HOME/applications" || true

info "Done. Open Discord from your app menu, or run 'discord'."
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) info "Note: ~/.local/bin isn't in your PATH, so the 'discord' command won't work until it is." ;; esac
