/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP's chevron for Plasma's System Tray, placed right before it: instead
    of Plasma's popup it shows the hidden icons in the tray itself. Drawn
    with the Plasma theme's arrows and tool button.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg

PlasmoidItem {
    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: anchorItem

        readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
        readonly property rect area: panelArea.rect

        PanelArea {
            id: panelArea
            target: anchorItem
        }

        // Room for the chevron only while there is something to show
        Layout.minimumWidth: showChevron ? chevron.width + 2 : 0
        Layout.maximumWidth: Layout.minimumWidth

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
            interval: 1000
            repeat: true
            // Vertical panels keep Plasma's own arrow
            running: anchorItem.horizontal && !anchorItem.tray && !!anchorItem.Window.window
            triggeredOnStart: true
            onTriggered: {
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
                }
            }
        }

        // Centred on the taskbar's height; the arrow points right while the
        // hidden icons are shown
        Item {
            id: chevron
            visible: anchorItem.showChevron
            y: Math.round(anchorItem.area.y + (anchorItem.area.height - height) / 2)
            width: 18
            height: 18

            KSvg.FrameSvgItem {
                anchors.fill: parent
                visible: chevronMouse.containsMouse
                imagePath: "widgets/button"
                prefix: chevronMouse.pressed ? "toolbutton-pressed" : "toolbutton-hover"
            }
            KSvg.SvgItem {
                anchors.centerIn: parent
                width: 10
                height: 10
                imagePath: "widgets/arrows"
                elementId: anchorItem.trayExpanded ? "right-arrow" : "left-arrow"
            }
            MouseArea {
                id: chevronMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: anchorItem.trayExpanded = !anchorItem.trayExpanded
            }
        }
    }
}
