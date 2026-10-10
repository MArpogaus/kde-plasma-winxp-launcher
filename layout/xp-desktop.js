// SPDX-License-Identifier: GPL-2.0-or-later
//
// Plasma desktop script (run through org.kde.PlasmaShell.evaluateScript):
// replaces the bottom panels with an XP taskbar and sets the wallpaper.
// install.sh fills in the start icon and wallpaper placeholders below.

var startIcon = "@START_ICON@";
var wallpaper = "@WALLPAPER@";

var panel = new Panel;
panel.location = "bottom";
// Only replace the bottom panels on the screen the taskbar goes to, so other
// screens keep theirs
panels().forEach(function (p) {
    if (p.id !== panel.id && p.location === "bottom" && p.screen === panel.screen) {
        p.remove();
    }
});
panel.height = 30;
// Plasma 6: an XP taskbar spans the whole screen and does not float
panel.floating = false;
panel.lengthMode = "fill";
panel.alignment = "left";
panel.hiding = "none";

var start = panel.addWidget("com.github.marpogaus.winxpstartmenu");
start.currentConfigGroup = ["General"];
if (startIcon.length > 0) {
    start.writeConfig("startIcon", startIcon);
}
// Meta opens the start menu
start.currentConfigGroup = ["Shortcuts"];
start.writeConfig("global", "Alt+F1");

panel.addWidget("com.github.marpogaus.winxptaskbar");
panel.addWidget("com.github.marpogaus.winxptray");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("com.github.marpogaus.winxpclock");

if (wallpaper.length > 0) {
    desktops().forEach(function (d) {
        d.wallpaperPlugin = "org.kde.image";
        d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
        d.writeConfig("Image", wallpaper);
        d.writeConfig("FillMode", "2");
    });
}
