/*
    SPDX-License-Identifier: GPL-2.0-or-later

    A cascading menu window, placed next to the row it belongs to like
    XP's (see placeAt()). In the XP start menu it has XP's cascade frame
    from the Plasma theme (widgets/winxp, cascade-*: border, blue band,
    shadow); otherwise, and in the Classic Start menu, the theme's dialog
    frame (Luna's plain menus).
*/
import QtQuick
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker

Kicker.SubMenu {
    id: dialog

    property QtObject xp
    property QtObject controller
    property var model: null
    property int level: 0
    // Long menus wrap into more columns (or scroll) to fit the screen
    // without its panels, inside the window's frame
    readonly property int maxRows: Math.max(5, Math.floor(
        (controller.availableArea.height - insetTop - insetBottom - shadow) / xp.cascadeRowHeight))

    KSvg.Svg {
        id: winxp
        imagePath: "widgets/winxp"
    }
    // Cascades are rebuilt each time they open, so this follows theme changes
    readonly property bool xpFrame: !controller.classic && winxp.hasElement("cascade-center")
    // The rows' distance from the frame's outer edges (the dialog's own
    // frame adds its margins outside); XP's frame has a shadow (right and
    // bottom) that is not part of the menu
    readonly property real insetLeft: xpFrame ? frame.margins.left : 0
    readonly property real insetTop: xpFrame ? frame.margins.top : margins.top
    readonly property real insetBottom: xpFrame ? frame.margins.top : margins.bottom
    readonly property real shadow: xpFrame ? frame.margins.bottom - frame.margins.top : 0
    // XP's cascades overlap the menu they come from by 2 px
    readonly property int overlap: xpFrame ? 2 : 0

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

        // The menu without its shadow
        const menuWidth = width - shadow;
        const menuHeight = height - shadow;
        let x;
        let y;
        if (parentMenu) {
            const parentRight = parentMenu.x + parentMenu.width - (parentMenu.shadow ?? 0);
            x = parentRight - overlap;
            if (x + width > right) {
                x = parentMenu.x + overlap - menuWidth;
            }
            y = rowTop - insetTop;
            if (y + height > bottom) {
                y = rowBottom + insetBottom - menuHeight;
            }
        } else {
            x = Math.min(Math.round(row.x + anchorItem.width), right - width);
            y = rowBottom + insetBottom - menuHeight;
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

    backgroundHints: xpFrame ? PlasmaCore.Dialog.NoBackground : PlasmaCore.Dialog.StandardBackground

    mainItem: Item {
        width: cascadeView.width + (dialog.xpFrame ? frame.margins.left + frame.margins.right : 0)
        height: cascadeView.height + (dialog.xpFrame ? frame.margins.top + frame.margins.bottom : 0)

        KSvg.FrameSvgItem {
            id: frame
            anchors.fill: parent
            visible: dialog.xpFrame
            imagePath: "widgets/winxp"
            prefix: "cascade"
        }

        CascadeMenuView {
            id: cascadeView
            x: dialog.insetLeft
            y: dialog.xpFrame ? frame.margins.top : 0
            xp: dialog.xp
            controller: dialog.controller
            model: dialog.model
            level: dialog.level
            maxRows: dialog.maxRows
            frameWidth: (dialog.xpFrame ? frame.margins.left + frame.margins.right : 0) + dialog.margins.left + dialog.margins.right

            Keys.onEscapePressed: dialog.controller.closeCascadesFrom(dialog.level)
        }
    }
}
