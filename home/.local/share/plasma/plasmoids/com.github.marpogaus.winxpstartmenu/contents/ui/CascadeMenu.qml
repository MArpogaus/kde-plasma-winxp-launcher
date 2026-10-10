/*
    SPDX-License-Identifier: GPL-2.0-or-later

    A cascading menu window, placed next to the row it belongs to like
    XP's (see placeAt()).
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

    // The row the cascade belongs to and the menu that row is in. Measured
    // on XP: the cascade's frame overlaps that menu by 2 px (its left
    // border lies 1 px left of the menu's right border; mirrored when it
    // opens to the left) and its top border lies 1 px above the row, or,
    // when that runs off the screen, its bottom border 1 px below it. The
    // All Programs menu (no parent menu) starts right after the button,
    // its bottom border right below the button.
    property Item anchorItem: null
    property Item parentMenu: null

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
        const frameWidth = cascadeView.width - cascadeView.shadow;
        const frameHeight = cascadeView.height - cascadeView.shadow;
        const rowTop = Math.round(row.y);
        const rowBottom = Math.round(row.y + anchorItem.height);

        let x;
        let y;
        if (parentMenu) {
            const menu = parentMenu.mapToGlobal(0, 0);
            x = Math.round(menu.x + parentMenu.width) - 2;
            if (x + cascadeView.width > right) {
                x = Math.round(menu.x) + 2 - frameWidth;
            }
            y = rowTop - 1;
            if (y + cascadeView.height > bottom) {
                y = rowBottom + 1 - frameHeight;
            }
        } else {
            x = Math.min(Math.round(row.x + anchorItem.width), right - cascadeView.width);
            y = rowBottom + 1 - frameHeight;
        }
        dialog.x = Math.max(area.x, x);
        dialog.y = Math.max(area.y, y);

        // An open child cascade follows
        const child = controller.cascades[level + 1];
        if (child) {
            child.reposition();
        }
    }

    visible: false
    // Keyboard focus stays with the start menu window.
    flags: Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: false

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
