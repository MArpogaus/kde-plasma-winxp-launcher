/*
    SPDX-License-Identifier: GPL-2.0-or-later

    A cascading menu window with the Plasma theme's dialog frame, placed
    next to the row it belongs to like XP's (see placeAt()).
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
    // Long menus wrap into more columns (or scroll) to fit the screen
    // without its panels, inside the theme's dialog frame
    readonly property int maxRows: Math.max(5, Math.floor(
        (controller.availableArea.height - margins.top - margins.bottom) / xp.cascadeRowHeight))

    readonly property alias view: cascadeView

    // The row the cascade belongs to and the menu window that row is in.
    // The cascade opens beside that menu (mirrored when there is no room)
    // with its first row level with the row, or, when that runs off the
    // screen, ending level with it. All Programs (no parent menu) starts
    // right after its button and ends level with the button's bottom.
    property Item anchorItem: null
    property var parentMenu: null

    function placeAt(item, menu) {
        anchorItem = item;
        parentMenu = menu;
        reposition();
    }

    function reposition() {
        if (!anchorItem || !anchorItem.Window.window) {
            return;
        }
        const row = anchorItem.mapToGlobal(0, 0);
        // The screen area free of panels, in global coordinates
        const area = controller.availableArea;
        const right = area.x + area.width;
        const bottom = area.y + area.height;
        const rowTop = Math.round(row.y);
        const rowBottom = Math.round(row.y + anchorItem.height);

        let x;
        let y;
        if (parentMenu) {
            x = parentMenu.x + parentMenu.width;
            if (x + width > right) {
                x = parentMenu.x - width;
            }
            y = rowTop - margins.top;
            if (y + height > bottom) {
                y = rowBottom + margins.bottom - height;
            }
        } else {
            x = Math.min(Math.round(row.x + anchorItem.width), right - width);
            y = rowBottom + margins.bottom - height;
        }
        dialog.x = Math.max(area.x, x);
        dialog.y = Math.max(area.y, y);

        // An open child cascade follows
        const child = controller.cascades[level + 1];
        if (child) {
            child.reposition();
        }
    }

    onWidthChanged: reposition()
    onHeightChanged: reposition()

    visible: false
    // Keyboard focus stays with the start menu window.
    flags: Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: false

    onActiveChanged: controller.checkActivation()

    mainItem: CascadeMenuView {
        id: cascadeView
        xp: dialog.xp
        controller: dialog.controller
        model: dialog.model
        level: dialog.level
        maxRows: dialog.maxRows

        Keys.onEscapePressed: dialog.controller.closeCascadesFrom(dialog.level)
    }
}
