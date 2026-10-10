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
    type: PlasmaCore.Dialog.Normal
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: false

    function open(newMode) {
        mode = newMode;
        // No visual parent: centre on the screen like XP does
        const area = dialog.screen ? dialog.screen.availableGeometry : null;
        if (area) {
            dialog.x = Math.round(area.x + (area.width - dialog.width) / 2);
            dialog.y = Math.round(area.y + (area.height - dialog.height) / 2);
        }
        visible = true;
        requestActivate();
        dialogView.forceActiveFocus();
    }

    Component.onCompleted: {
        if ("backgroundHints" in dialog) {
            dialog.backgroundHints = PlasmaCore.Dialog.NoBackground;
        }
    }

    mainItem: SessionDialogView {
        id: dialogView
        xp: dialog.xp
        onActivated: action => {
            dialog.visible = false;
            dialog.activated(action);
        }
    }
}
