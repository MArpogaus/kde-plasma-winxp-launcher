#!/bin/sh
# Install or upgrade the Windows XP Start Menu widget for the current user.
set -e
cd "$(dirname "$0")"
if kpackagetool6 --type Plasma/Applet --list | grep -q "com.github.marpogaus.winxpstartmenu"; then
    kpackagetool6 --type Plasma/Applet --upgrade package
else
    kpackagetool6 --type Plasma/Applet --install package
fi
echo "Done. Restart plasmashell (systemctl --user restart plasma-plasmashell) to load the new version."
