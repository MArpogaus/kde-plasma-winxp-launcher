#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Maintainer script: refresh the third-party files bundled in home/ (Exposé,
# modernXP cursors) from their upstream projects. Users do not need this,
# they copy home/. Needs git and curl. URLs can be overridden with
# WINXP_*_URL for testing.
set -euo pipefail
for tool in git curl; do
    command -v "$tool" >/dev/null || { echo "error: $tool is required" >&2; exit 1; }
done
cd "$(dirname "$0")/.."
ROOT=$PWD
SRC=$(mktemp -d)
trap 'rm -rf "$SRC"' EXIT

clone() { git clone --quiet --depth 1 "$@"; }
clone "${WINXP_EXPOSE_URL:-https://www.opencode.net/phob1an/expose.git}" "$SRC/expose"
curl -fsSL "${WINXP_CURSORS_URL:-https://github.com/na0miluv/modernXP-cursor-theme/releases/download/final/ModernXP.tar.gz}" \
    | tar -xz -C "$SRC"
curl -fsSL "${WINXP_CURSORS_LICENSE_URL:-https://raw.githubusercontent.com/na0miluv/modernXP-cursor-theme/main/LICENSE}" \
    -o "$SRC/ModernXP/LICENSE"

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
# the repository may spell the wallpaper's directory as Bl#U00f8ff
shopt -s nullglob
blaff=("$E"/wallpapers/Bl*)
shopt -u nullglob
[ "${#blaff[@]}" -eq 1 ] || { echo "expected one Bløff wallpaper directory, found ${#blaff[@]}" >&2; exit 1; }
replace "${blaff[0]}" "$D/wallpapers/Bløff"
mkdir -p "$D/color-schemes"
cp "$E/Expose.colors" "$D/color-schemes/Expose.colors"
printf '[General]\ntheme=Expose\n' > "$H/.config/Kvantum/kvantum.kvconfig"

# modernXP cursors (GPL-3.0), the project's own release build
replace "$SRC/ModernXP" "$D/icons/ModernXP"

echo "Vendored files refreshed in home/. Review with: git status home/"
