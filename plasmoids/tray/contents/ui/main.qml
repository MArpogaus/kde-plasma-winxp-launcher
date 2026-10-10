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
        readonly property point windowPos: {
            x; y; width; height; Window.width; Window.height;
            return Window.window ? mapToItem(null, 0, 0) : Qt.point(0, 0);
        }

        // Room for the bevel before the first tray icon
        Layout.minimumWidth: horizontal ? 10 : -1
        Layout.maximumWidth: horizontal ? 10 : -1
        Layout.minimumHeight: horizontal ? -1 : 10
        Layout.maximumHeight: horizontal ? -1 : 10

        Item {
            id: block
            // horizontal: from here to the right window edge, full height
            x: 0
            y: anchorItem.horizontal ? -anchorItem.windowPos.y : 0
            width: anchorItem.horizontal ? Window.width - anchorItem.windowPos.x : anchorItem.width
            height: anchorItem.horizontal ? Window.height : Window.height - anchorItem.windowPos.y

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
    }
}
