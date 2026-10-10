#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Maintainer script: refresh the third-party files bundled in home/ (Exposé,
# modernXP cursors, Dolphin's XP toolbar) from their upstream projects. Users do not need this, they copy home/.
# Needs git, python3 and rsvg-convert. URLs can be overridden with
# WINXP_*_URL for testing.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
SRC=$(mktemp -d)
trap 'rm -rf "$SRC"' EXIT

clone() { git clone --quiet --depth 1 "$@"; }
clone "${WINXP_EXPOSE_URL:-https://www.opencode.net/phob1an/expose.git}" "$SRC/expose"
clone "${WINXP_CURSORS_URL:-https://github.com/na0miluv/modernXP-cursor-theme.git}" "$SRC/cursors"
curl -fsSL "${WINXP_DOLPHIN_RC_URL:-https://raw.githubusercontent.com/KDE/dolphin/master/src/dolphinui.rc}" -o "$SRC/dolphinui.rc"

H=$ROOT/home
D=$H/.local/share
replace() { rm -rf "$2"; mkdir -p "$(dirname "$2")"; cp -r "$1" "$2"; }

# Exposé by phob1an, unmodified (GPL; wallpapers CC BY-SA), at the paths the
# Windows XP Global Theme's contents/defaults refers to (taken from Exposé's
# own Plasma 6 Global Theme, org.magpie.expose.desktop)
E=$SRC/expose
replace "$E/desktoptheme/expose" "$D/plasma/desktoptheme/expose"
replace "$E/themes/expose" "$D/aurorae/themes/expose"
replace "$E/Kvantum/Expose" "$H/.config/Kvantum/Expose"
replace "$E/wallpapers/expose" "$D/wallpapers/expose"
# the archive may spell the wallpaper's directory as Bl#U00f8ff
for dir in "$E"/wallpapers/Bl*; do replace "$dir" "$D/wallpapers/Bløff"; done
mkdir -p "$D/color-schemes"
cp "$E/Expose.colors" "$D/color-schemes/Expose.colors"
printf '[General]\ntheme=Expose\n' > "$H/.config/Kvantum/kvantum.kvconfig"


# modernXP cursors (GPL-3.0), built at 32, 64 and 96 px
C=$SRC/cursors/src
for size in 32 64 96; do
    mkdir -p "$SRC/png/$size"
    for svg in "$C"/svg/*.svg; do
        rsvg-convert -w "$size" -h "$size" -o "$SRC/png/$size/$(basename "${svg%.svg}").png" "$svg"
    done
done
rm -rf "$D/icons/ModernXP"
python3 tools/xcursor.py --config-dir "$C/config" --png-root "$SRC/png" --aliases "$C/cursorList" \
    --out "$D/icons/ModernXP" --name "Modern XP" 2>/dev/null
cp "$SRC/cursors/LICENSE" "$D/icons/ModernXP/LICENSE"

# Dolphin: XP Explorer toolbar
mkdir -p "$D/kxmlgui5/dolphin"
python3 tools/patch-dolphin-ui.py "$SRC/dolphinui.rc" "$D/kxmlgui5/dolphin/dolphinui.rc"

echo "Vendored files refreshed in home/. Review with: git status home/"
