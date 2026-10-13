/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP's notification area for Plasma's System Tray, placed right before
    it: the light blue block under the tray and the clock (widgets later
    in the panel are painted on top of earlier ones, so it reaches to the
    end of the panel) and the round chevron, which shows the hidden icons
    in the tray itself instead of Plasma's popup. Both come from the
    Plasma theme (widgets/winxp, tray-*); without them the theme's arrow
    and tool button stand in for the chevron.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
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

        KSvg.Svg {
            id: winxp
            imagePath: "widgets/winxp"
            // Checked again when the Plasma theme changes
            property bool present: hasElement("tray-center")
            onRepaintNeeded: present = hasElement("tray-center")
        }
        readonly property bool xpArea: winxp.present

        // XP's chevron sits centred on the block's edge, so it reaches 8 px
        // left of it; keep that (plus 3 px) inside this widget so it never
        // covers the task buttons
        readonly property int blockLeft: xpArea && showChevron ? 11 : 0
        // Room for the block's edge and the chevron, or just the chevron;
        // on a vertical taskbar a strip at the block's top
        Layout.minimumWidth: !horizontal ? -1
                           : xpArea ? blockLeft + (showChevron ? 17 : 10)
                           : showChevron ? chevron.width + 2 : 0
        Layout.maximumWidth: Layout.minimumWidth
        Layout.minimumHeight: horizontal ? -1 : xpArea ? 10 : 0
        Layout.maximumHeight: Layout.minimumHeight

        // The block, from here to the end of the visible taskbar
        KSvg.FrameSvgItem {
            visible: anchorItem.xpArea
            x: anchorItem.horizontal ? anchorItem.blockLeft : anchorItem.area.x
            y: anchorItem.horizontal ? anchorItem.area.y : 0
            width: anchorItem.horizontal ? anchorItem.area.x + anchorItem.area.width - anchorItem.blockLeft : anchorItem.area.width
            height: anchorItem.horizontal ? anchorItem.area.height : anchorItem.area.y + anchorItem.area.height
            imagePath: "widgets/winxp"
            prefix: "tray"
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

        // On XP's blue taskbar the tray's icons and texts take the colour
        // set for contrasting areas, like this pack's widgets (Plasma's
        // panel gives its widgets the Window set, black on white popups)
        Binding {
            target: anchorItem.tray ? anchorItem.tray.Kirigami.Theme : null
            property: "colorSet"
            value: Kirigami.Theme.Complementary
            when: anchorItem.xpArea
        }
        Binding {
            target: anchorItem.tray ? anchorItem.tray.Kirigami.Theme : null
            property: "inherit"
            value: false
            when: anchorItem.xpArea
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
                // Plasma leaves a hidden item's tooltip title out (and the
                // tooltip off) when its label shows the name; the row hides
                // the label. As Plasma, no tooltip over an open applet
                if (!item.mainText) {
                    item.mainText = Qt.binding(() => item.text);
                    item.active = Qt.binding(() => (item.mainText !== "" || item.subText.length > 0) && !(item.applet && item.applet.expanded));
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

        onTrayChanged: if (!tray) trayFinder.attempts = 0
        Connections {
            target: Plasmoid.containment
            function onAppletAdded() {
                trayFinder.attempts = 0;
            }
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

        // Looks for the tray for a minute, and again when a widget is added
        // to the panel or the tray goes away (it reloads)
        Timer {
            id: trayFinder
            property int attempts: 0
            interval: 1000
            repeat: true
            // Vertical panels keep Plasma's own arrow
            running: anchorItem.horizontal && !anchorItem.tray && !!anchorItem.Window.window && attempts < 60
            triggeredOnStart: true
            onTriggered: {
                ++attempts;
                // everything of the tray used here, so a Plasma without it
                // keeps its own arrow
                const tray = anchorItem.findItem(anchorItem.Window.contentItem,
                    i => "systemTrayState" in i && "hiddenLayout" in i
                         && "hiddenModel" in i && "visibleLayout" in i && "itemSize" in i);
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
        // hidden icons are shown. XP's is centred on the block's 2 px edge
        // line and drawn 1:1.
        Item {
            id: chevron
            visible: anchorItem.showChevron
            x: anchorItem.xpArea ? anchorItem.blockLeft + 1 - width / 2 : 0
            y: Math.round(anchorItem.area.y + (anchorItem.area.height - height) / 2)
            width: 18
            height: anchorItem.xpArea ? 19 : 18
            opacity: anchorItem.xpArea && chevronMouse.pressed ? 0.8 : 1

            KSvg.SvgItem {
                anchors.fill: parent
                visible: anchorItem.xpArea
                svg: winxp
                elementId: anchorItem.trayExpanded ? "tray-chevron-right" : "tray-chevron-left"
            }
            KSvg.FrameSvgItem {
                anchors.fill: parent
                visible: !anchorItem.xpArea && chevronMouse.containsMouse
                imagePath: "widgets/button"
                prefix: chevronMouse.pressed ? "toolbutton-pressed" : "toolbutton-hover"
            }
            KSvg.SvgItem {
                anchors.centerIn: parent
                visible: !anchorItem.xpArea
                width: Math.min(naturalSize.width, 10)
                height: Math.min(naturalSize.height, 10)
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
