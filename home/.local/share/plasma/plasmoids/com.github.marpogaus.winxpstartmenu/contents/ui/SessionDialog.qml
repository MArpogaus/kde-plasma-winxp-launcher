/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Window for the XP Turn Off / Log Off dialogs. Its title is the marker
    the "Windows XP Session Fade" KWin effect looks for to fade the rest
    of the screen to grey while it is shown.
*/
import QtQuick
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: dialog

    property QtObject xp
    property alias mode: dialogView.mode
    property alias flagIcon: dialogView.flagIcon

    signal activated(string action)

    title: "WinXP Session Dialog"
    visible: false
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: false

    // Global geometry of the screen to centre on (the panel's screen). A
    // binding, not a one-off assignment, so it also holds once shown.
    property rect screenGeometry

    x: screenGeometry.x + Math.round((screenGeometry.width - dialogView.width) / 2)
    y: screenGeometry.y + Math.round((screenGeometry.height - dialogView.height) / 2)

    function open(newMode) {
        mode = newMode;
        visible = true;
        requestActivate();
        dialogView.forceActiveFocus();
    }

    backgroundHints: PlasmaCore.Dialog.NoBackground

    mainItem: SessionDialogView {
        id: dialogView
        xp: dialog.xp
        onActivated: action => {
            dialog.visible = false;
            dialog.activated(action);
        }
    }
}
