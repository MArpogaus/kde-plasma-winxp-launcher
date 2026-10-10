/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Draws XP's light blue notification area. Widgets that come later in the
    panel are painted on top of earlier ones, so this widget, placed right
    before the System Tray, paints the block from its own position to the
    end of the panel and the tray and clock show up on it.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: anchorItem

        readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
        readonly property rect area: panelArea.rect

        PanelArea {
            id: panelArea
            target: anchorItem
        }

        // Room for the bevel before the first tray icon
        Layout.minimumWidth: horizontal ? 10 : -1
        Layout.maximumWidth: horizontal ? 10 : -1
        Layout.minimumHeight: horizontal ? -1 : 10
        Layout.maximumHeight: horizontal ? -1 : 10

        Item {
            id: block
            // From here to the end of the visible taskbar, over its full height
            x: anchorItem.horizontal ? 0 : anchorItem.area.x
            y: anchorItem.horizontal ? anchorItem.area.y : 0
            width: anchorItem.horizontal ? anchorItem.area.x + anchorItem.area.width : anchorItem.area.width
            height: anchorItem.horizontal ? anchorItem.area.height : anchorItem.area.y + anchorItem.area.height

            // Sampled from the XP notification area (30 rows)
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#0c59b9" }
                    GradientStop { position: 0.04; color: "#149eed" }
                    GradientStop { position: 0.08; color: "#1399eb" }
                    GradientStop { position: 0.12; color: "#1290e8" }
                    GradientStop { position: 0.35; color: "#118fe9" }
                    GradientStop { position: 0.50; color: "#0d8dea" }
                    GradientStop { position: 0.66; color: "#0d93ed" }
                    GradientStop { position: 0.80; color: "#0d9cf0" }
                    GradientStop { position: 0.93; color: "#0fa0ef" }
                    GradientStop { position: 1.00; color: "#1583db" }
                }
            }
            // Left edge: dark shadow, then a light line
            Rectangle {
                width: 1
                height: parent.height
                color: "#0a3e98"
            }
            Rectangle {
                x: 1
                width: 1
                height: parent.height
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1fb6e8" }
                    GradientStop { position: 1.0; color: "#18b4f3" }
                }
            }
        }

        // The System Tray's "show hidden icons" arrow only takes its icon
        // from the icon theme. Give it XP's round chevron instead: find it
        // in the panel (the tray loads after this widget and can reload)
        // and point its two icons, collapsed and expanded, at our images.
        property QtObject expander: null

        function findExpander(item) {
            if ("wasExpanded" in item && "arrowAnimationDuration" in item) {
                return item;
            }
            const children = item.children;
            for (let i = 0; i < children.length; ++i) {
                const found = findExpander(children[i]);
                if (found) {
                    return found;
                }
            }
            return null;
        }

        Timer {
            interval: 1000
            repeat: true
            running: !anchorItem.expander && !!anchorItem.Window.window
            triggeredOnStart: true
            onTriggered: {
                const expander = anchorItem.findExpander(anchorItem.Window.contentItem);
                if (!expander) {
                    return;
                }
                const icons = Array.from(expander.children).filter(c => "source" in c);
                if (icons.length !== 2) {
                    return;
                }
                icons[0].source = Qt.resolvedUrl("../images/chevron-left.svg");
                icons[1].source = Qt.resolvedUrl("../images/chevron-right.svg");
                anchorItem.expander = expander;
            }
        }
    }
}
