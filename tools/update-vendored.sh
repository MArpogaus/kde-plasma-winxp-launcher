#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Maintainer script: refresh the third-party files bundled in home/ from
# their upstream projects. Users do not need this, they copy home/.
# Needs git, python3 and rsvg-convert. URLs can be overridden with
# WINXP_*_URL for testing.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
SRC=$(mktemp -d)
trap 'rm -rf "$SRC"' EXIT

clone() { git clone --quiet --depth 1 "$@"; }
clone "${WINXP_EXPOSE_URL:-https://www.opencode.net/phob1an/expose.git}" "$SRC/expose"
clone --filter=blob:none --sparse "${WINXP_LUNA_URL:-https://github.com/klapeto/KDE-Plasma-Luna.git}" "$SRC/luna"
git -C "$SRC/luna" sparse-checkout set home/dot-local/icons/Luna
clone "${WINXP_CURSORS_URL:-https://github.com/na0miluv/modernXP-cursor-theme.git}" "$SRC/cursors"
curl -fsSL "${WINXP_DOLPHIN_RC_URL:-https://raw.githubusercontent.com/KDE/dolphin/master/src/dolphinui.rc}" -o "$SRC/dolphinui.rc"

H=$ROOT/home
D=$H/.local/share
replace() { rm -rf "$2"; mkdir -p "$(dirname "$2")"; cp -r "$1" "$2"; }

# Exposé (GPL-3.0, wallpaper CC BY-SA 4.0)
E=$SRC/expose
replace "$E/desktoptheme/expose" "$D/plasma/desktoptheme/expose"
replace "$E/themes/expose" "$D/aurorae/themes/Expose"
replace "$E/Kvantum/Expose" "$H/.config/Kvantum/Expose"
replace "$E/wallpapers/expose" "$D/wallpapers/Expose"
mkdir -p "$D/color-schemes"
cp "$E/Expose.colors" "$D/color-schemes/Expose.colors"
SPLASH=$D/plasma/look-and-feel/com.github.marpogaus.winxp/contents/splash
replace "$E/look-and-feel/Expose/contents/splash" "$SPLASH"
# Upstream's splash is Qt 5 only: QtGraphicalEffects and PlasmaCore.Units no
# longer exist in Plasma 6 (neither is actually used for drawing)
sed -i -E '/^import (QtGraphicalEffects|org\.kde\.plasma\.core)\b/d; /PlasmaCore\.Units/d' "$SPLASH/Splash.qml"

# Luna icons (GPL-3.0); XP never uses more than 48 px, keep up to 128 px for HiDPI
L=$D/icons/Luna
replace "$SRC/luna/home/dot-local/icons/Luna" "$L"
rm -rf "$L"/256x256 "$L"/512x512
sed -i -E '/^(Directories|ScaledDirectories)=/{s#([=,])(256x256|512x512)/[a-z]+#\1#g; s#,+#,#g; s#=,#=#; s#,$##}
    /^\[(256x256|512x512)\//,/^$/d' "$L/index.theme"
cp "$SRC/luna/LICENSE" "$L/LICENSE" 2>/dev/null || git -C "$SRC/luna" show HEAD:LICENSE > "$L/LICENSE"

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
