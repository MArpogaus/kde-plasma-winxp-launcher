/*
    SPDX-License-Identifier: GPL-2.0-or-later

    A cascading menu window. Kicker's SubMenu dialog places itself to the
    right of its visual parent (top aligned) and flips/shifts to stay on
    screen, which is exactly how XP cascades behave.
*/
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker

Kicker.SubMenu {
    id: dialog

    property QtObject xp
    property QtObject controller
    property var model: null
    property int level: 0
    property int maxRows: 30

    readonly property alias view: cascadeView

    // When set, the window is placed by hand: left edge at the item's right
    // edge, bottom edge on the item's bottom edge (the All Programs menu).
    property Item bottomAnchor: null

    function alignBottomTo(item) {
        bottomAnchor = item;
        reposition();
    }

    function reposition() {
        if (!bottomAnchor || !bottomAnchor.Window.window) {
            return;
        }
        const corner = bottomAnchor.mapToGlobal(bottomAnchor.width, bottomAnchor.height);
        const screen = bottomAnchor.Window.window.screen;
        const top = screen ? screen.availableGeometry.y : 0;
        // the view's drop shadow hangs below/right of the frame
        dialog.x = Math.round(corner.x) - 1;
        dialog.y = Math.max(top, Math.round(corner.y) - (cascadeView.height - cascadeView.shadow));
    }

    visible: false
    // Keyboard focus stays with the start menu window.
    flags: Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: false
    offset: -2

    onActiveChanged: controller.checkActivation()

    Component.onCompleted: {
        if ("backgroundHints" in dialog) {
            dialog.backgroundHints = PlasmaCore.Dialog.NoBackground;
        }
    }

    mainItem: CascadeMenuView {
        id: cascadeView
        xp: dialog.xp
        controller: dialog.controller
        model: dialog.model
        level: dialog.level
        maxRows: dialog.maxRows

        Keys.onEscapePressed: dialog.controller.closeCascadesFrom(dialog.level)
        onHeightChanged: dialog.reposition()
        onWidthChanged: dialog.reposition()
    }
}
