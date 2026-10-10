#!/bin/sh
# Install or upgrade the Windows XP widgets and the KWin session fade effect
# for the current user.
set -e
cd "$(dirname "$0")"

install_package() { # type dir id
    if kpackagetool6 --type "$1" --list 2>/dev/null | grep -q "$3"; then
        kpackagetool6 --type "$1" --upgrade "$2"
    else
        kpackagetool6 --type "$1" --install "$2"
    fi
}

install_package Plasma/Applet plasmoids/startmenu com.github.marpogaus.winxpstartmenu
install_package Plasma/Applet plasmoids/taskbar com.github.marpogaus.winxptaskbar
install_package Plasma/Applet plasmoids/tray com.github.marpogaus.winxptray
install_package Plasma/Applet plasmoids/clock com.github.marpogaus.winxpclock
install_package KWin/Effect kwin/sessionfade winxp_sessionfade

kwriteconfig6 --file kwinrc --group Plugins --key winxp_sessionfadeEnabled true
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "Done. Restart plasmashell to load new versions: systemctl --user restart plasma-plasmashell"
