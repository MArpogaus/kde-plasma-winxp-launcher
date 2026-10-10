/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Draws XP's light blue notification area. Widgets that come later in the
    panel are painted on top of earlier ones, so this widget, placed right
    before the System Tray, paints the block from just after the chevron's
    room to the end of the panel and the tray and clock show up on it.
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

        // The chevron reaches 11 px left of the block; keep that (plus 3 px)
        // inside this widget so it never covers the task buttons
        readonly property int blockLeft: showChevron ? 14 : 0

        // Room for the bevel (and the chevron) before the first tray icon
        Layout.minimumWidth: horizontal ? blockLeft + (showChevron ? 14 : 10) : -1
        Layout.maximumWidth: Layout.minimumWidth
        Layout.minimumHeight: horizontal ? -1 : 10
        Layout.maximumHeight: horizontal ? -1 : 10

        Item {
            id: block
            // From here to the end of the visible taskbar, over its full height
            x: anchorItem.horizontal ? anchorItem.blockLeft : anchorItem.area.x
            y: anchorItem.horizontal ? anchorItem.area.y : 0
            width: anchorItem.horizontal ? anchorItem.area.x + anchorItem.area.width - anchorItem.blockLeft : anchorItem.area.width
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

        // XP's round chevron. Plasma's own "show hidden icons" arrow opens a
        // popup; XP instead widens the notification area in place. So hide
        // Plasma's arrow and, while expanded, let the tray's list of shown
        // icons take the hidden ones too (and its hidden list none): the
        // same move Plasma makes when an app's icon becomes active, so it is
        // immediate. The tray is found in the panel once it has loaded (it
        // comes after this widget) and again whenever it reloads.
        property Item tray: null
        property Item expander: null
        property bool trayExpanded: false
        property var originalFilters: null
        readonly property bool showChevron: horizontal && tray !== null
            && (trayExpanded || tray.hiddenLayout.itemCount > 0)

        onTrayExpandedChanged: {
            if (!tray) {
                return;
            }
            const shown = tray.visibleLayout.model;
            const hidden = tray.hiddenModel;
            if (!originalFilters) {
                originalFilters = { shown: shown.filterRowCallback, hidden: hidden.filterRowCallback };
            }
            if (trayExpanded) {
                shown.filterRowCallback = (row, parent) => {
                    const status = shown.sourceModel.data(shown.sourceModel.index(row, 0, parent), shown.filterRole);
                    return status === PlasmaCore.Types.ActiveStatus || status === PlasmaCore.Types.PassiveStatus;
                };
                hidden.filterRowCallback = () => false;
                Qt.callLater(fitShownItems);
                fitRetry.restart();
            } else {
                shown.filterRowCallback = originalFilters.shown;
                hidden.filterRowCallback = originalFilters.hidden;
            }
        }

        // Hidden icons keep their status while shown in the row, and Plasma
        // lays a hidden item out as in its popup list (32 px icon, margins,
        // a text label). Give them the row's look instead. Collapsing
        // destroys these items; one that turned active meanwhile keeps the
        // overrides, which equal Plasma's own row layout.
        function fitShownItems() {
            if (!tray || !trayExpanded) {
                return;
            }
            const plasmaTray = tray;
            const children = tray.visibleLayout.contentItem.children;
            for (let i = 0; i < children.length; ++i) {
                const item = children[i].item;
                if (!item || !item.inHiddenLayout || !item.iconContainer) {
                    continue;
                }
                const icon = item.iconContainer;
                const row = icon.parent;
                icon.implicitWidth = Qt.binding(() => plasmaTray.itemSize);
                icon.implicitHeight = Qt.binding(() => item.height);
                row.anchors.margins = 0;
                for (let j = 0; j < row.children.length; ++j) {
                    if (row.children[j] !== icon) {
                        row.children[j].visible = false;
                    }
                }
            }
        }

        Timer {
            id: fitRetry
            interval: 250
            onTriggered: anchorItem.fitShownItems()
        }

        Connections {
            target: anchorItem.tray ? anchorItem.tray.visibleLayout : null
            function onCountChanged() {
                Qt.callLater(anchorItem.fitShownItems);
            }
        }
        // An icon already in the row can turn hidden while expanded
        Connections {
            target: anchorItem.tray ? anchorItem.tray.visibleLayout.model : null
            function onDataChanged() {
                Qt.callLater(anchorItem.fitShownItems);
            }
        }
        // Plasma's own activation of the tray (shortcut, keyboard) opens
        // its popup of hidden icons; collapse first so it is not empty.
        // An icon's own popup (volume, network, …) keeps the row expanded.
        Connections {
            target: anchorItem.tray ? anchorItem.tray.systemTrayState : null
            function onExpandedChanged() {
                const state = anchorItem.tray.systemTrayState;
                if (state.expanded && !state.activeApplet) {
                    anchorItem.trayExpanded = false;
                }
            }
        }

        // Hands the tray back as Plasma made it: its arrow and its filters
        // (when this widget goes away or the panel turns vertical)
        function releaseTray() {
            if (!tray) {
                return;
            }
            trayExpanded = false;
            const plasmaTray = tray;
            if (expander) {
                expander.visible = Qt.binding(() => plasmaTray.hiddenLayout.itemCount > 0);
            }
            tray = null;
            expander = null;
        }

        onHorizontalChanged: {
            if (!horizontal) {
                releaseTray();
            }
        }
        Component.onDestruction: releaseTray()

        function findItem(item, test) {
            if (test(item)) {
                return item;
            }
            const children = item.children;
            for (let i = 0; i < children.length; ++i) {
                const found = findItem(children[i], test);
                if (found) {
                    return found;
                }
            }
            return null;
        }

        Timer {
            property int attempts: 0
            // Every second at first, then rarely when the panel has no tray
            interval: attempts < 30 ? 1000 : 10000
            repeat: true
            // Vertical panels keep Plasma's own arrow
            running: anchorItem.horizontal && !anchorItem.tray && !!anchorItem.Window.window
            triggeredOnStart: true
            onTriggered: {
                ++attempts;
                const tray = anchorItem.findItem(anchorItem.Window.contentItem,
                    i => "systemTrayState" in i && "hiddenLayout" in i && "plasmoid" in i);
                const expander = tray && anchorItem.findItem(tray,
                    i => "wasExpanded" in i && "arrowAnimationDuration" in i);
                if (expander) {
                    expander.visible = false;
                    anchorItem.originalFilters = null;
                    anchorItem.trayExpanded = false;
                    anchorItem.expander = expander;
                    anchorItem.tray = tray;
                    attempts = 0;
                }
            }
        }

        // As on XP: starts 11 px left of the block's edge (in the room this
        // widget keeps for it), centred on the taskbar's height, drawn 1:1;
        // the arrow points right while the hidden icons are shown
        Image {
            visible: anchorItem.showChevron
            x: anchorItem.blockLeft - 11
            y: Math.round(anchorItem.area.y + (anchorItem.area.height - height) / 2)
            width: 18
            height: 19
            source: anchorItem.trayExpanded ? "../images/chevron-right.svg" : "../images/chevron-left.svg"
            sourceSize: Qt.size(width, height)
            smooth: false
            opacity: chevronMouse.pressed ? 0.8 : 1

            MouseArea {
                id: chevronMouse
                anchors.fill: parent
                onClicked: anchorItem.trayExpanded = !anchorItem.trayExpanded
            }
        }
    }
}
