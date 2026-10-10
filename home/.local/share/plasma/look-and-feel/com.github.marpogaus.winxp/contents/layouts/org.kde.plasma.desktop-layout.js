// SPDX-License-Identifier: GPL-2.0-or-later
//
// Desktop layout of the Windows XP Global Theme: one 30 px taskbar at the
// bottom with Start, Quick Launch, task buttons, the notification area and the clock.
// The look (Exposé) comes from contents/defaults.

var panel = new Panel;
panel.location = "bottom";
panel.height = 30;
// An XP taskbar spans the whole screen and does not float
panel.floating = false;
panel.lengthMode = "fill";
panel.alignment = "left";
panel.hiding = "none";

var start = panel.addWidget("com.github.marpogaus.winxpstartmenu");
// Meta opens the start menu
start.currentConfigGroup = ["Shortcuts"];
start.writeConfig("global", "Alt+F1");

panel.addWidget("com.github.marpogaus.winxpquicklaunch");

panel.addWidget("com.github.marpogaus.winxptaskbar");
panel.addWidget("com.github.marpogaus.winxptray");
var tray = panel.addWidget("org.kde.plasma.systemtray");
// XP keeps the expand arrow at the left end of the notification area.
// Older Plasma keeps the tray's settings in a separate containment; newer
// Plasma makes the tray applet itself the containment.
var trayContainmentId = tray.readConfig("SystrayContainmentId");
var trayConfig = (trayContainmentId && desktopById(trayContainmentId)) || tray;
trayConfig.currentConfigGroup = ["General"];
trayConfig.writeConfig("reverseIconOrder", true);
trayConfig.writeConfig("iconSpacing", 1);
// XP hides inactive icons behind the chevron; keep volume, network,
// battery and app icons in view
trayConfig.writeConfig("hiddenItems", [
    "org.kde.plasma.clipboard",
    "org.kde.plasma.brightness",
    "org.kde.plasma.bluetooth",
    "org.kde.plasma.notifications",
    "org.kde.plasma.keyboardindicator",
    "org.kde.plasma.printmanager",
    "org.kde.plasma.cameraindicator",
    "org.kde.plasma.manage-inputmethod",
    "org.kde.kdeconnect",
]);
panel.addWidget("com.github.marpogaus.winxpclock");

// XP's desktop icons are 32 px, which the XP icon theme has as sharp
// bitmaps (Plasma's default 64 px would scale them up)
desktops().forEach(function (desktop) {
    desktop.currentConfigGroup = ["General"];
    desktop.writeConfig("iconSize", 1);
});
