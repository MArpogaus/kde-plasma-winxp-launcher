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

    // The row the cascade belongs to. XP puts the cascade's frame 3 px to
    // the right of the menu the row is in, with its first row level with
    // that row, or, when that runs off the screen, its last row level with
    // it. The All Programs menu (bottomFirst) always takes the second form
    // and touches the left column instead of leaving a gap.
    property Item anchorItem: null
    property bool bottomFirst: false

    // Frame (1 px border + 1 px padding) around the rows, and the gap
    // between two menus
    readonly property int inset: 2
    readonly property int gap: bottomFirst ? -1 : 3

    function placeAt(item, alignBottom) {
        anchorItem = item;
        bottomFirst = alignBottom;
        reposition();
    }

    function reposition() {
        if (!anchorItem || !anchorItem.Window.window) {
            return;
        }
        const topLeft = anchorItem.mapToGlobal(0, 0);
        const screen = anchorItem.Window.window.screen;
        const area = screen ? screen.availableGeometry : Qt.rect(0, 0, 1e6, 1e6);
        const frameWidth = cascadeView.width - cascadeView.shadow;
        const frameHeight = cascadeView.height - cascadeView.shadow;
        // All Programs lines its frame up with the button itself
        const parentInset = bottomFirst ? 0 : inset;

        let x = Math.round(topLeft.x + anchorItem.width) + parentInset + gap;
        if (x + frameWidth > area.x + area.width) {
            // No room on the right: open to the left of the parent menu
            x = Math.round(topLeft.x) - parentInset - gap - frameWidth;
        }
        const below = Math.round(topLeft.y) - parentInset;
        const above = Math.round(topLeft.y + anchorItem.height) + parentInset - frameHeight;
        let y = !bottomFirst && below + frameHeight <= area.y + area.height ? below : above;
        dialog.x = Math.max(area.x, x);
        dialog.y = Math.max(area.y, y);
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
