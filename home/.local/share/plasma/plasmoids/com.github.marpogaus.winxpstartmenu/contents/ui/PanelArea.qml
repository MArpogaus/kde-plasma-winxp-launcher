/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Geometry of the visible panel, in `target`'s coordinates.

    Plasma's Panel.qml draws the panel as a FrameSvgItem with imagePath
    ".../widgets/panel-background" and puts the applets inside it with some
    padding, so an applet is smaller than the taskbar it sits in. XP's
    start button, task buttons and notification area are laid out on the
    whole taskbar, so they use this rectangle. Falls back to the target's
    own rectangle (e.g. on the desktop or in a preview).
*/
import QtQuick

QtObject {
    required property Item target

    function findBackground() {
        for (let p = target; p; p = p.parent) {
            const children = p.children;
            for (let i = 0; i < children.length; ++i) {
                const c = children[i];
                if (c.visible && typeof c.imagePath === "string"
                        && c.imagePath.endsWith("widgets/panel-background") && c.height > 0) {
                    return c;
                }
            }
        }
        return null;
    }

    readonly property Item background: {
        target.Window.width;
        target.Window.height;
        return target.Window.window ? findBackground() : null;
    }

    readonly property rect rect: {
        const t = target;
        t.width;
        t.height;
        for (let p = t; p; p = p.parent) {
            p.x;
            p.y;
        }
        const b = background;
        if (!b) {
            return Qt.rect(0, 0, t.width, t.height);
        }
        b.x;
        b.y;
        b.width;
        b.height;
        return b.mapToItem(t, 0, 0, b.width, b.height);
    }
}
