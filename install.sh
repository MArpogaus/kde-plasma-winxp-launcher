#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# One-click Windows XP transformation for KDE Plasma 6.
#
#   ./install.sh               install / update everything for the current user
#   ./install.sh --uninstall   restore the previous look and remove everything
#
# Phase 1 downloads every resource first; nothing on the system is touched
# unless all of them are available. Phase 2 builds cursors, icons and the
# Dolphin layout, phase 3 backs up the current configuration, phase 4
# installs files and phase 5 applies the settings.
#
# Third-party content is downloaded from its upstream projects at install
# time and is not part of this repository:
#   Exposé (Plasma, window, Kvantum, SDDM theme)   www.opencode.net/phob1an/expose
#   KDE Plasma Luna (traced XP icons, Bliss)        github.com/klapeto/KDE-Plasma-Luna
#   xfce-winxp-tc (XP fonts, icons, wallpapers,     github.com/rozniak/xfce-winxp-tc
#                  start flag, fallback cursors)
#   modernXP cursors                                github.com/na0miluv/modernXP-cursor-theme
#   Windows XP sound theme                          github.com/wonordel/Windows-XP-Sound-Theme-KDE
# Fonts, sounds and bitmaps from Windows are (C) Microsoft Corp.

set -euo pipefail

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------
SELF_URL=${WINXP_SELF_URL:-https://github.com/MArpogaus/kde-plasma-winxp-launcher.git}
SELF_BRANCH=${WINXP_SELF_BRANCH:-claude/panam-xp-startmenu-widget-cad1lu}
EXPOSE_URL=${WINXP_EXPOSE_URL:-https://www.opencode.net/phob1an/expose.git}
LUNA_URL=${WINXP_LUNA_URL:-https://github.com/klapeto/KDE-Plasma-Luna.git}
WINTC_URL=${WINXP_WINTC_URL:-https://github.com/rozniak/xfce-winxp-tc.git}
CURSORS_URL=${WINXP_CURSORS_URL:-https://github.com/na0miluv/modernXP-cursor-theme.git}
SOUNDS_URL=${WINXP_SOUNDS_URL:-https://github.com/wonordel/Windows-XP-Sound-Theme-KDE.git}
DOLPHIN_RC_URL=${WINXP_DOLPHIN_RC_URL:-https://raw.githubusercontent.com/KDE/dolphin}

DATA=${XDG_DATA_HOME:-$HOME/.local/share}
CONF=${XDG_CONFIG_HOME:-$HOME/.config}
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/winxp-kde
STATE=$DATA/winxp-kde
MANIFEST=$STATE/manifest
BACKUP=$STATE/backup

ICON_THEME=WindowsXP-Luna
SOUND_THEME=WindowsXP

WITH_SDDM=0
WITH_PANEL=1
WITH_DOLPHIN=1
ICONS_ARCHIVE=""
UNINSTALL=0

usage() {
    cat <<EOF
Usage: $0 [options]

  --uninstall        restore the configuration saved by the first install and
                     remove everything this script installed
  --with-sddm        also install the Exposé login screen (asks for sudo)
  --no-panel         keep the current panels (only install the widgets)
  --no-dolphin       do not change Dolphin's toolbar and views
  --icons FILE|URL   use this icon theme archive instead of the XP icons
  -h, --help         show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --uninstall) UNINSTALL=1 ;;
        --with-sddm) WITH_SDDM=1 ;;
        --no-panel) WITH_PANEL=0 ;;
        --no-dolphin) WITH_DOLPHIN=0 ;;
        --icons) ICONS_ARCHIVE=${2:?--icons needs a file or URL}; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m    warning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

qdbus_cmd() {
    if have qdbus6; then qdbus6 "$@"; elif have qdbus; then qdbus "$@"; else return 1; fi
}

# Record a path so --uninstall can remove it
track() { mkdir -p "$STATE"; echo "$1" >> "$MANIFEST"; }

# Copy a directory into place (replacing an older copy) and track it
install_dir() { # src dst
    rm -rf "$2"
    mkdir -p "$(dirname "$2")"
    cp -r "$1" "$2"
    track "$2"
}

install_file() { # src dst
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    track "$2"
}

# Shallow, optionally sparse clone into $CACHE/src/<name>
fetch_git() { # name url [sparse paths...]
    local name=$1 url=$2; shift 2
    local dir=$CACHE/src/$name
    rm -rf "$dir"
    if [ $# -gt 0 ]; then
        git clone --quiet --depth 1 --filter=blob:none --sparse "$url" "$dir" &&
            git -C "$dir" sparse-checkout set "$@"
    else
        git clone --quiet --depth 1 "$url" "$dir"
    fi
}

download() { # url file
    if have curl; then curl -fsSL "$1" -o "$2"; else wget -q "$1" -O "$2"; fi
}

kwrite() { kwriteconfig6 "$@"; }

# --------------------------------------------------------------------------
# Uninstall
# --------------------------------------------------------------------------
uninstall() {
    [ -f "$MANIFEST" ] || die "Nothing to uninstall ($MANIFEST not found)."

    step "Stopping Plasma to restore its layout"
    have kquitapp6 && kquitapp6 plasmashell >/dev/null 2>&1 || true

    step "Restoring configuration from $BACKUP/original"
    if [ -d "$BACKUP/original" ]; then
        (cd "$BACKUP/original" && find . -type f) | while read -r f; do
            mkdir -p "$(dirname "$CONF/$f")"
            cp "$BACKUP/original/$f" "$CONF/$f"
            info "restored ${f#./}"
        done
        # Files that did not exist before the first install
        if [ -f "$BACKUP/original.absent" ]; then
            while read -r f; do rm -f "$CONF/$f"; done < "$BACKUP/original.absent"
        fi
    fi

    step "Removing installed files"
    sort -u "$MANIFEST" | while read -r path; do
        case "$path" in
            kpackage:*)
                IFS=: read -r _ type id <<< "$path"
                kpackagetool6 --type "$type" --remove "$id" >/dev/null 2>&1 || true ;;
            sudo:*)
                sudo rm -rf "${path#sudo:}" ;;
            *) rm -rf "$path" ;;
        esac
    done
    if [ -f "$BACKUP/original-dolphinui.rc" ]; then
        mkdir -p "$DATA/kxmlgui5/dolphin"
        cp "$BACKUP/original-dolphinui.rc" "$DATA/kxmlgui5/dolphin/dolphinui.rc"
    fi
    if [ -f "$BACKUP/original-dolphin-global.directory" ]; then
        mkdir -p "$DATA/dolphin/view_properties/global"
        cp "$BACKUP/original-dolphin-global.directory" "$DATA/dolphin/view_properties/global/.directory"
    fi
    have fc-cache && fc-cache -f >/dev/null 2>&1 || true
    rm -rf "$STATE"

    step "Starting Plasma"
    if have kstart; then kstart plasmashell >/dev/null 2>&1 &
    else (plasmashell >/dev/null 2>&1 &); fi
    qdbus_cmd org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    echo
    echo "Done. Log out and back in to reload fonts, cursors and the window style everywhere."
}

if [ "$UNINSTALL" = 1 ]; then
    uninstall
    exit 0
fi

# --------------------------------------------------------------------------
# Phase 0: requirements
# --------------------------------------------------------------------------
step "Checking requirements"
missing=()
for tool in git python3 kpackagetool6 kwriteconfig6; do
    have "$tool" || missing+=("$tool")
done
have curl || have wget || missing+=("curl")
[ ${#missing[@]} -eq 0 ] || die "Missing: ${missing[*]}. This pack needs KDE Plasma 6."
RASTERIZER=""
if have rsvg-convert; then RASTERIZER=rsvg; elif have inkscape; then RASTERIZER=inkscape; fi
[ -n "$RASTERIZER" ] || warn "rsvg-convert/inkscape not found: using XP's original (non-HiDPI) cursors instead of modernXP"
have kvantummanager || warn "Kvantum is not installed: applications keep their current style (install 'kvantum' and re-run)"

# --------------------------------------------------------------------------
# Phase 1: fetch every resource before changing anything
# --------------------------------------------------------------------------
step "Downloading resources"
mkdir -p "$CACHE/src" "$CACHE/build"

HERE=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")
if [ -n "$HERE" ] && [ -d "$HERE/plasmoids/startmenu" ]; then
    SELF=$HERE
    info "widgets: $SELF"
else
    info "widgets: $SELF_URL"
    fetch_git self "$SELF_URL" || die "could not download the widgets"
    git -C "$CACHE/src/self" fetch --quiet --depth 1 origin "$SELF_BRANCH" 2>/dev/null &&
        git -C "$CACHE/src/self" checkout --quiet FETCH_HEAD 2>/dev/null || true
    SELF=$CACHE/src/self
fi

failed=()
info "Exposé theme"
fetch_git expose "$EXPOSE_URL" || failed+=("Exposé ($EXPOSE_URL)")
info "Luna icons and wallpaper"
fetch_git luna "$LUNA_URL" \
    home/dot-local/icons/Luna \
    home/dot-local/plasma/desktoptheme/Luna/wallpapers/Bliss || failed+=("Luna ($LUNA_URL)")
info "XP fonts, icons, wallpapers and cursors"
fetch_git wintc "$WINTC_URL" \
    fonts/ttf icons/luna wallpapers/common cursors/with-shadow/standard \
    themes/luna/blue/Resources || failed+=("xfce-winxp-tc ($WINTC_URL)")
info "modernXP cursors"
fetch_git cursors "$CURSORS_URL" || failed+=("modernXP cursors ($CURSORS_URL)")
info "XP sounds"
fetch_git sounds "$SOUNDS_URL" || failed+=("sound theme ($SOUNDS_URL)")

DOLPHIN_RC=""
if [ "$WITH_DOLPHIN" = 1 ] && have dolphin; then
    version=$(dolphin --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
    DOLPHIN_RC=$CACHE/src/dolphinui.rc
    info "Dolphin ${version:-unknown} toolbar definition"
    download "$DOLPHIN_RC_URL/v$version/src/dolphinui.rc" "$DOLPHIN_RC" 2>/dev/null ||
        download "$DOLPHIN_RC_URL/master/src/dolphinui.rc" "$DOLPHIN_RC" ||
        failed+=("dolphinui.rc ($DOLPHIN_RC_URL)")
fi

ICONS_SRC=""
if [ -n "$ICONS_ARCHIVE" ]; then
    info "icon theme $ICONS_ARCHIVE"
    ICONS_SRC=$CACHE/src/icons-archive
    rm -rf "$ICONS_SRC"; mkdir -p "$ICONS_SRC"
    archive=$ICONS_ARCHIVE
    if [ ! -f "$archive" ]; then
        archive=$CACHE/src/icons-archive.download
        download "$ICONS_ARCHIVE" "$archive" || failed+=("icons ($ICONS_ARCHIVE)")
    fi
    if [ -f "$archive" ]; then
        # Downloads are saved without their extension, so look at the content
        if python3 -c 'import sys, zipfile; sys.exit(not zipfile.is_zipfile(sys.argv[1]))' "$archive"; then
            python3 -m zipfile -e "$archive" "$ICONS_SRC"
        else
            tar -xf "$archive" -C "$ICONS_SRC"
        fi || failed+=("icons: cannot unpack $ICONS_ARCHIVE")
    fi
fi

# Every file the later phases rely on
E=$CACHE/src/expose L=$CACHE/src/luna W=$CACHE/src/wintc
required=(
    "$SELF/packages.list" "$SELF/install-widgets.sh" "$SELF/layout/xp-desktop.js"
    "$E/desktoptheme/expose" "$E/themes/expose" "$E/Expose.colors" "$E/Kvantum/Expose"
    "$E/look-and-feel/Expose"
    "$L/home/dot-local/icons/Luna/index.theme"
    "$L/home/dot-local/plasma/desktoptheme/Luna/wallpapers/Bliss"
    "$W/fonts/ttf/tahoma.ttf" "$W/icons/luna/mappings" "$W/wallpapers/common"
    "$W/cursors/with-shadow/standard/mappings" "$W/themes/luna/blue/Resources/start_flag.png"
    "$CACHE/src/cursors/src/config" "$CACHE/src/cursors/src/cursorList" "$CACHE/src/cursors/src/svg"
    "$CACHE/src/sounds/index.theme"
)
while read -r _ dir id; do
    [ -n "$id" ] && required+=("$SELF/$dir/metadata.json")
done < <(grep -v '^#' "$SELF/packages.list")
[ "$WITH_SDDM" = 1 ] && required+=("$E/sddm/themes/expose")
for path in "${required[@]}"; do
    case "$path" in
        "$E"/*) [ -e "$E" ] || continue ;;      # already reported as failed
        "$L"/*) [ -e "$L" ] || continue ;;
        "$W"/*) [ -e "$W" ] || continue ;;
    esac
    [ -e "$path" ] || failed+=("missing ${path#"$CACHE/src/"}")
done
if [ ${#failed[@]} -gt 0 ]; then
    printf '    \033[1;31mfailed:\033[0m %s\n' "${failed[@]}" >&2
    die "Not all resources could be downloaded. Nothing was changed."
fi
info "all resources downloaded"

# --------------------------------------------------------------------------
# Phase 2: build
# --------------------------------------------------------------------------
step "Building cursors, icons and Dolphin layout"
B=$CACHE/build
rm -rf "$B"; mkdir -p "$B"

if [ -n "$RASTERIZER" ]; then
    CURSOR_THEME=ModernXP
    src=$CACHE/src/cursors/src
    for size in 32 64 96; do
        mkdir -p "$B/cursor-png/$size"
        for svg in "$src"/svg/*.svg; do
            png=$B/cursor-png/$size/$(basename "${svg%.svg}").png
            if [ "$RASTERIZER" = rsvg ]; then
                rsvg-convert -w "$size" -h "$size" -o "$png" "$svg"
            else
                inkscape -o "$png" -w "$size" -h "$size" "$svg" >/dev/null 2>&1
            fi
        done
    done
    python3 "$SELF/tools/xcursor.py" --config-dir "$src/config" --png-root "$B/cursor-png" \
        --aliases "$src/cursorList" --out "$B/$CURSOR_THEME" --name "Modern XP" 2>/dev/null
else
    CURSOR_THEME=WindowsXP-Standard
    src=$W/cursors/with-shadow/standard
    python3 "$SELF/tools/xcursor.py" --config-dir "$src/cfg" --png-root "$src/res" \
        --aliases "$src/mappings" --out "$B/$CURSOR_THEME" --name "Windows XP Standard"
fi

if [ -n "$ICONS_SRC" ]; then
    index=$(find "$ICONS_SRC" -name index.theme | head -1)
    [ -n "$index" ] || die "the icon archive contains no index.theme"
    ICON_DIR=$(dirname "$index")
    ICON_THEME=$(basename "$ICON_DIR")
else
    python3 "$SELF/tools/build-icon-theme.py" --source "$W/icons/luna" --out "$B/$ICON_THEME" \
        --name "Windows XP (Luna)" --inherits "Luna,breeze,hicolor"
    ICON_DIR=$B/$ICON_THEME
fi

if [ -n "$DOLPHIN_RC" ]; then
    python3 "$SELF/tools/patch-dolphin-ui.py" "$DOLPHIN_RC" "$B/dolphinui.rc" ||
        { warn "could not adapt Dolphin's toolbar"; DOLPHIN_RC=""; }
fi

# --------------------------------------------------------------------------
# Phase 3: back up the current configuration (first run only)
# --------------------------------------------------------------------------
CONFIG_FILES=(kdeglobals kwinrc plasmarc kcminputrc ksplashrc dolphinrc
    plasma-org.kde.plasma.desktop-appletsrc plasmashellrc Kvantum/kvantum.kvconfig)
step "Backing up the current configuration"
if [ ! -d "$BACKUP/original" ]; then
    mkdir -p "$BACKUP/original"
    : > "$BACKUP/original.absent"
    for f in "${CONFIG_FILES[@]}"; do
        if [ -f "$CONF/$f" ]; then
            mkdir -p "$(dirname "$BACKUP/original/$f")"
            cp "$CONF/$f" "$BACKUP/original/$f"
        else
            echo "$f" >> "$BACKUP/original.absent"
        fi
    done
    info "saved to $BACKUP/original (used by --uninstall)"
else
    info "keeping the backup from the first install: $BACKUP/original"
fi
# Dolphin's toolbar file and global view properties are user files too
if [ ! -e "$BACKUP/original-dolphinui.rc" ] && [ -f "$DATA/kxmlgui5/dolphin/dolphinui.rc" ]; then
    cp "$DATA/kxmlgui5/dolphin/dolphinui.rc" "$BACKUP/original-dolphinui.rc"
fi
DOLPHIN_PROPS=$DATA/dolphin/view_properties/global/.directory
if [ ! -e "$BACKUP/original-dolphin-global.directory" ] && [ -f "$DOLPHIN_PROPS" ] &&
    ! grep -qxF "$DOLPHIN_PROPS" "$MANIFEST" 2>/dev/null; then
    cp "$DOLPHIN_PROPS" "$BACKUP/original-dolphin-global.directory"
fi

# --------------------------------------------------------------------------
# Phase 4: install files
# --------------------------------------------------------------------------
step "Installing fonts, icons, cursors, sounds and wallpapers"
mkdir -p "$DATA/fonts/WindowsXP"
track "$DATA/fonts/WindowsXP"
cp "$W"/fonts/ttf/*.ttf "$DATA/fonts/WindowsXP/"
have fc-cache && fc-cache -f "$DATA/fonts" >/dev/null 2>&1 || true

install_dir "$L/home/dot-local/icons/Luna" "$DATA/icons/Luna"
install_dir "$ICON_DIR" "$DATA/icons/$ICON_THEME"
install_dir "$B/$CURSOR_THEME" "$DATA/icons/$CURSOR_THEME"
install_dir "$CACHE/src/sounds" "$DATA/sounds/$SOUND_THEME"
rm -rf "$DATA/sounds/$SOUND_THEME/.git"

install_dir "$L/home/dot-local/plasma/desktoptheme/Luna/wallpapers/Bliss" "$DATA/wallpapers/Bliss"
mkdir -p "$DATA/wallpapers/WindowsXP"
track "$DATA/wallpapers/WindowsXP"
cp "$W"/wallpapers/common/*.jpg "$DATA/wallpapers/WindowsXP/"
WALLPAPER=$(find "$DATA/wallpapers/Bliss/contents/images" -type f | sort | tail -1)

install_file "$W/themes/luna/blue/Resources/start_flag.png" "$STATE/start_flag.png"

step "Installing the Exposé theme"
install_dir "$E/desktoptheme/expose" "$DATA/plasma/desktoptheme/expose"
install_dir "$E/look-and-feel/Expose" "$DATA/plasma/look-and-feel/org.magpie.expose.desktop"
install_dir "$E/themes/expose" "$DATA/aurorae/themes/Expose"
install_file "$E/Expose.colors" "$DATA/color-schemes/Expose.colors"
install_dir "$E/Kvantum/Expose" "$CONF/Kvantum/Expose"
for wp in "$E"/wallpapers/*/; do
    [ -f "$wp/metadata.json" ] && install_dir "$wp" "$DATA/wallpapers/Expose-$(basename "$wp")"
done

step "Installing the XP widgets, effect and Alt+Tab switcher"
"$SELF/install-widgets.sh" | sed 's/^/    /'
grep -v '^#' "$SELF/packages.list" | while read -r type _ id; do
    [ -n "$id" ] && track "kpackage:$type:$id"
done

if [ "$WITH_SDDM" = 1 ]; then
    step "Installing the Exposé login screen (sudo)"
    sudo rm -rf /usr/share/sddm/themes/expose
    sudo cp -r "$E/sddm/themes/expose" /usr/share/sddm/themes/expose
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=expose\n' | sudo tee /etc/sddm.conf.d/winxp-kde.conf >/dev/null
    track "sudo:/usr/share/sddm/themes/expose"
    track "sudo:/etc/sddm.conf.d/winxp-kde.conf"
fi

# --------------------------------------------------------------------------
# Phase 5: apply
# --------------------------------------------------------------------------
step "Applying the XP look"
have plasma-apply-colorscheme && plasma-apply-colorscheme Expose >/dev/null || true
have plasma-apply-desktoptheme && plasma-apply-desktoptheme expose >/dev/null || true
have plasma-apply-cursortheme && plasma-apply-cursortheme "$CURSOR_THEME" >/dev/null || true
kwrite --file kcminputrc --group Mouse --key cursorTheme "$CURSOR_THEME"
kwrite --file kcminputrc --group Mouse --key cursorSize 32

kwrite --file kdeglobals --group Icons --key Theme "$ICON_THEME"
for changeicons in /usr/lib*/libexec/plasma-changeicons /usr/lib/*/libexec/plasma-changeicons; do
    [ -x "$changeicons" ] && { "$changeicons" "$ICON_THEME" >/dev/null 2>&1 || true; break; }
done

# Fonts: Tahoma 8 pt like XP, Trebuchet MS Bold for window titles
kwrite --file kdeglobals --group General --key font "Tahoma,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwrite --file kdeglobals --group General --key menuFont "Tahoma,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwrite --file kdeglobals --group General --key toolBarFont "Tahoma,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwrite --file kdeglobals --group General --key smallestReadableFont "Tahoma,7,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwrite --file kdeglobals --group General --key fixed "Lucida Console,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwrite --file kdeglobals --group WM --key activeFont "Trebuchet MS,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
kwrite --file kdeglobals --group General --key XftHintStyle hintfull
kwrite --file kdeglobals --group General --key XftSubPixel rgb
kwrite --file kdeglobals --group General --key XftAntialias true

# XP opens files with a double click
kwrite --file kdeglobals --group KDE --key SingleClick false
kwrite --file kdeglobals --group KDE --key LookAndFeelPackage org.magpie.expose.desktop

if have kvantummanager; then
    kvantummanager --set Expose >/dev/null 2>&1 || kwrite --file Kvantum/kvantum.kvconfig --group General --key theme Expose
    kwrite --file kdeglobals --group KDE --key widgetStyle kvantum
fi

# Window borders: Exposé Aurorae theme, XP button layout
kwrite --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwrite --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Expose
kwrite --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft M
kwrite --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX

kwrite --file ksplashrc --group KSplash --key Engine KSplashQML
kwrite --file ksplashrc --group KSplash --key Theme org.magpie.expose.desktop

kwrite --file kdeglobals --group Sounds --key Theme "$SOUND_THEME"
kwrite --file kdeglobals --group Sounds --key Enable true

if [ -n "$DOLPHIN_RC" ]; then
    step "Configuring Dolphin like XP's Explorer"
    install_file "$B/dolphinui.rc" "$DATA/kxmlgui5/dolphin/dolphinui.rc"
    kwrite --file dolphinrc --group MainWindow --key MenuBar Enabled
    kwrite --file dolphinrc --group MainWindow --group "Toolbar mainToolBar" --key ToolButtonStyle TextBesideIcon
    kwrite --file dolphinrc --group MainWindow --group "Toolbar mainToolBar" --key IconSize 24
    kwrite --file dolphinrc --group General --key EditableUrl true
    kwrite --file dolphinrc --group General --key ShowFullPath true
    kwrite --file dolphinrc --group General --key ShowStatusBar true
    kwrite --file dolphinrc --group General --key ShowZoomSlider false
    kwrite --file dolphinrc --group General --key GlobalViewProps true
    # "Tiles": 48 px icons with name, type and size next to them
    kwrite --file dolphinrc --group CompactMode --key IconSize 48
    kwrite --file dolphinrc --group CompactMode --key PreviewSize 48
    props=$DATA/dolphin/view_properties/global
    mkdir -p "$props"
    track "$props/.directory"
    printf '[Dolphin]\nVersion=4\nViewMode=2\nVisibleRoles=Compact_text,Compact_type,Compact_size,Details_text,Details_size,Details_type,Details_modificationtime\nSortFoldersFirst=true\n' > "$props/.directory"
fi

if [ "$WITH_PANEL" = 1 ]; then
    step "Building the XP taskbar"
    script=$(sed -e "s|@START_ICON@|$STATE/start_flag.png|" -e "s|@WALLPAPER@|file://$WALLPAPER|" \
        "$SELF/layout/xp-desktop.js")
    if ! qdbus_cmd org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null; then
        warn "could not talk to plasmashell; log in to Plasma and re-run, or use --no-panel"
    fi
elif have plasma-apply-wallpaperimage; then
    plasma-apply-wallpaperimage "$WALLPAPER" >/dev/null 2>&1 || true
fi

qdbus_cmd org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true

echo
echo "Windows XP is ready. Log out and back in once so every application picks up"
echo "the fonts, cursors and style. Undo everything with: $0 --uninstall"
