#!/bin/sh
# Install or upgrade the Windows XP widgets, the session fade effect and the
# Alt+Tab switcher (packages.list) for the current user, and enable the
# latter two. ./install.sh does the full desktop transformation.
set -e
cd "$(dirname "$0")"

grep -v '^#' packages.list | while read -r type dir id; do
    [ -n "$id" ] || continue
    # --list is read fully: grep -q could stop it early (SIGPIPE)
    if kpackagetool6 --type "$type" --list 2>/dev/null | grep -F "$id" >/dev/null; then
        kpackagetool6 --type "$type" --upgrade "$dir" >/dev/null
    else
        kpackagetool6 --type "$type" --install "$dir" >/dev/null
    fi
    echo "$type $id"
done

kwriteconfig6 --file kwinrc --group Plugins --key winxp_sessionfadeEnabled true
kwriteconfig6 --file kwinrc --group TabBox --key LayoutName winxp_alttab
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "Done. Restart plasmashell to load new versions: systemctl --user restart plasma-plasmashell"
