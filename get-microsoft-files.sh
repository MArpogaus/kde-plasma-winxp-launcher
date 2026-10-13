#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Optional: fetch the Microsoft-owned Windows XP files this repository does
# not redistribute (fonts, icons, sounds, Bliss and the other XP wallpapers,
# the original start flag) from their community projects and
# switch to them. Run after copying home/ and applying the Global Theme.
set -euo pipefail
# Check first so a missing tool cannot leave the switch half done
for tool in git kwriteconfig6; do
    command -v "$tool" >/dev/null || { echo "error: $tool is required" >&2; exit 1; }
done
D=${XDG_DATA_HOME:-$HOME/.local/share}
SRC=$(mktemp -d)
trap 'rm -rf "$SRC"' EXIT

echo "Downloading from github.com/rozniak/xfce-winxp-tc and github.com/wonordel/Windows-XP-Sound-Theme-KDE"
git clone --quiet --depth 1 --filter=blob:none --sparse https://github.com/rozniak/xfce-winxp-tc "$SRC/wintc"
git -C "$SRC/wintc" sparse-checkout set fonts/ttf icons/luna wallpapers/common themes/luna/blue/Resources
git clone --quiet --depth 1 https://github.com/wonordel/Windows-XP-Sound-Theme-KDE "$SRC/sounds"
W=$SRC/wintc

mkdir -p "$D/fonts/WindowsXP" "$D/wallpapers/WindowsXP" "$D/winxp-kde" "$D/sounds"
cp "$W"/fonts/ttf/*.ttf "$D/fonts/WindowsXP/"
fc-cache -f "$D/fonts" >/dev/null 2>&1 || true
cp "$W"/wallpapers/common/*.jpg "$D/wallpapers/WindowsXP/"
cp "$W/themes/luna/blue/Resources/start_flag.png" "$D/winxp-kde/start_flag.png"
rm -rf "$D/sounds/WindowsXP"
cp -r "$SRC/sounds" "$D/sounds/WindowsXP"
rm -rf "$D/sounds/WindowsXP/.git"

# XP's icons (xfce-winxp-tc's Luna), built as its own build does: each
# mapping line "context/name-->image" links a freedesktop icon name to one
# of XP's images in every size
I=$D/icons/WindowsXP
rm -rf "$I"
mkdir -p "$I"
cp -r "$W/icons/luna/res" "$W/icons/luna/index.theme" "$I/"
link_icons() {
    local mapping icon res size
    while IFS= read -r mapping; do
        [ -n "$mapping" ] || continue
        icon=${mapping%%-->*}
        res=${mapping#*-->}
        if [[ $icon == *-symbolic ]]; then
            mkdir -p "$I/symbolic/${icon%/*}"
            ln -sf "../../res/svg/$res.svg" "$I/symbolic/$icon.svg"
            continue
        fi
        for size in "$I"/res/*x*; do
            size=${size##*/}
            mkdir -p "$I/$size/${icon%/*}"
            ln -sf "../../res/$size/$res.png" "$I/$size/$icon.png"
        done
    done
}
link_icons < "$W/icons/luna/mappings"
# KDE's names for XP Explorer's toolbar: Back, Forward, Up, Views
link_icons <<'MAPPINGS'
actions/go-previous-->nav_back
actions/go-next-->nav_forward
actions/go-parent-folder-->nav_parent_dir
actions/view-list-icons-->views
actions/view-list-details-->views
actions/view-list-tree-->views
MAPPINGS
# KDE skips directories whose context is not spelled as freedesktop.org's
# (file type icons would come from Breeze); Breeze fills in names XP lacks
sed -i 's/^Context=Mimetypes$/Context=MimeTypes/; s/^Context=Satus$/Context=Status/' "$I/index.theme"
grep -q '^Inherits=' "$I/index.theme" || sed -i 's/^Comment=.*/&\nInherits=breeze,hicolor/' "$I/index.theme"

# XP icons and sounds, Tahoma / Trebuchet MS, Bliss
kwriteconfig6 --file kdeglobals --group Icons --key Theme WindowsXP
kwriteconfig6 --file kdeglobals --group Sounds --key Theme WindowsXP
for key in font menuFont toolBarFont; do
    kwriteconfig6 --file kdeglobals --group General --key "$key" "Tahoma,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
done
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "Tahoma,7,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group WM --key activeFont "Trebuchet MS,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
plasma-apply-wallpaperimage "$D/wallpapers/WindowsXP/bliss.jpg" >/dev/null 2>&1 || true

echo "Done. Log out and back in so every application picks up the fonts."
