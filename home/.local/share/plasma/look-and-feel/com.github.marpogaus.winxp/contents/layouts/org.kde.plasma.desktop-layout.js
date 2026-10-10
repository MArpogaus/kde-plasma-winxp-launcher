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

// Meta and Alt+F1 open the start menu: Plasma's launcher shortcut finds
// it as the panel's application launcher (X-Plasma-Provides)
panel.addWidget("com.github.marpogaus.winxpstartmenu");

panel.addWidget("com.github.marpogaus.winxpquicklaunch");

panel.addWidget("com.github.marpogaus.winxptaskbar");
panel.addWidget("com.github.marpogaus.winxptray");
var tray = panel.addWidget("org.kde.plasma.systemtray");
// XP keeps the expand arrow at the left end of the notification area.
// Plasma 6 releases before the tray became a single containment keep its
// settings in a separate containment.
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

// XP's desktop icons are 32 px (Plasma's default is 64 px), filled in
// columns from the top left
desktops().forEach(function (desktop) {
    desktop.currentConfigGroup = ["General"];
    desktop.writeConfig("iconSize", 1);
    desktop.writeConfig("arrangement", 1);
});

// Behave like XP (keys checked against KWin's kwin.kcfg and effect metadata)
function setConfig(file, group, entries) {
    var config = ConfigFile(file, group);
    for (var key in entries) {
        config.writeEntry(key, entries[key]);
    }
}
// One desktop, as XP had
setConfig("kwinrc", "Desktops", { Number: 1, Rows: 1 });
// No hot corner (Overview sits in the top-left one by default; 9 = none)
setConfig("kwinrc", "Effect-overview", { BorderActivate: 9 });
// No snapping windows to half or full screen at the edges (Windows 7 came
// with that), no shake-to-find-cursor, no zoom when windows open or close;
// minimizing keeps KWin's default squash, like XP's shrink to the taskbar
setConfig("kwinrc", "Windows", { ElectricBorderMaximize: false, ElectricBorderTiling: false });
setConfig("kwinrc", "Plugins", { shakecursorEnabled: false, scaleEnabled: false, fadeEnabled: false, squashEnabled: true });
// XP's animations were quick
setConfig("kdeglobals", "KDE", { AnimationDurationFactor: 0.5, ScrollbarLeftClickNavigatesByPage: true });
// Busy cursor (arrow with hourglass) instead of a bouncing icon at app start
setConfig("klaunchrc", "BusyCursorSettings", { Bouncing: false });
