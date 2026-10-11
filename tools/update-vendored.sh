#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Maintainer script: refresh the third-party files bundled in home/ (Exposé
# and its Green and Metallic variants, modernXP cursors) from their upstream
# projects. Users do not need this,
# they copy home/. Needs git and curl.
set -euo pipefail
for tool in git curl; do
    command -v "$tool" >/dev/null || { echo "error: $tool is required" >&2; exit 1; }
done
cd "$(dirname "$0")/.."
ROOT=$PWD
SRC=$(mktemp -d)
trap 'rm -rf "$SRC"' EXIT

for repo in expose expose-green expose-metallic; do
    git clone --quiet --depth 1 "https://www.opencode.net/phob1an/$repo.git" "$SRC/$repo"
done
curl -fsSL https://github.com/na0miluv/modernXP-cursor-theme/releases/download/final/ModernXP.tar.gz \
    | tar -xz -C "$SRC"
curl -fsSL https://raw.githubusercontent.com/na0miluv/modernXP-cursor-theme/main/LICENSE -o "$SRC/ModernXP/LICENSE"

H=$ROOT/home
D=$H/.local/share
replace() { rm -rf "$2"; mkdir -p "$(dirname "$2")"; cp -r "$1" "$2"; }
# Plasma theme $1 from the Exposé checkout $2. The pack's XP files in it
# (marked "Part of the Windows XP pack") replace Exposé's: keep them over
# the refreshed theme
theme() {
    local t=$D/plasma/desktoptheme/$1 keep=$SRC/xp-$1
    mkdir -p "$keep"
    if [ -d "$t" ]; then
        (cd "$t" && { grep -rlZ "Part of the Windows XP pack" . || true; } | xargs -0r cp --parents -t "$keep")
    fi
    replace "$2/desktoptheme/$1" "$t"
    cp -r "$keep/." "$t/"
}

# Exposé by phob1an (GPL; wallpapers CC BY-SA), unmodified but for the pack's
# marked XP files in its Plasma theme (below), at the paths the
# Windows XP Global Theme's contents/defaults refers to (taken from Exposé's
# own Plasma 6 Global Theme, org.magpie.expose.desktop)
E=$SRC/expose
theme expose "$E"
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

# Exposé Green and Exposé Metallic, phob1an's Olive Green and Silver
# variants (GPL): Plasma theme, window borders, colours, Kvantum. Their
# Global Themes use Bløff (above) as XP did for every colour scheme.
for v in green:exposegreen:ExposeGreen metallic:exposemetallic:ExposeMetallic; do
    IFS=: read -r repo id name <<<"$v"
    V=$SRC/expose-$repo
    theme "$id" "$V"
    replace "$V/themes/$id" "$D/aurorae/themes/$id"
    replace "$V/Kvantum/$name" "$H/.config/Kvantum/$name"
    cp "$V/$name.colors" "$D/color-schemes/$name.colors"
done

# modernXP cursors (GPL-3.0), the project's own release build
replace "$SRC/ModernXP" "$D/icons/ModernXP"

echo "Vendored files refreshed in home/. Review with: git status home/"
