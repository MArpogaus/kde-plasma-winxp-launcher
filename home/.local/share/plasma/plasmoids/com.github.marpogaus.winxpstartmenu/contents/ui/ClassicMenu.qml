/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP's Classic Start menu: the pinned programs, Programs, Documents,
    Settings, Search, Help and Support, Run, Log Off and Turn Off
    Computer, with the "Windows XP Professional" banner on the left (not
    with small icons; XP drew it the same in every colour scheme).
    Geometry measured on a native XP screenshot (large icons: 32 px rows,
    9 px separators, banner 21 px wide). Frame, lines and colours come
    from the Plasma theme.

    All behaviour is delegated to `controller` (main.qml).
*/
import QtQuick

FocusScope {
    id: menu

    required property QtObject xp
    required property QtObject controller

    property var favoritesModel: null
    property string userName
    property bool showRun: true
    property bool showLogOff: true
    property string bannerTitle: "Windows XP"
    property string bannerEdition: "Professional"

    // Which top-level submenu is open ("programs", "documents", …)
    property string openCascade: ""

    readonly property bool smallIcons: xp.classicSmallIcons
    readonly property int rowHeight: xp.classicRowHeight
    // Rows start after the banner; the icon and text positions inside a
    // row follow from XP's 30 px icon and 66 px text offsets
    readonly property int rowsLeft: smallIcons ? 0 : xp.classicBannerWidth
    readonly property int iconLeft: smallIcons ? 3 : 6
    readonly property int iconSize: smallIcons ? 16 : 32
    readonly property int textSpacing: smallIcons ? 6 : 4

    readonly property var entries: {
        const list = [
            { key: "programs", icon: "applications-other", title: i18n("Programs"), arrow: true },
            { key: "documents", icon: "folder-documents", title: i18n("Documents"), arrow: true },
            { key: "settings", icon: "preferences-system", title: i18n("Settings"), arrow: true },
            { key: "search", icon: "system-search", title: i18n("Search"), arrow: true },
            { key: "help", icon: "help-browser", title: i18n("Help and Support") }
        ];
        if (showRun) {
            list.push({ key: "run", icon: "system-run", title: i18n("Run...") });
        }
        list.push({ separator: true });
        if (showLogOff) {
            list.push({ key: "logoff", icon: "system-log-out", title: i18n("Log Off %1...", userName) });
        }
        list.push({ key: "turnoff", icon: "system-shutdown", title: i18n("Turn Off Computer...") });
        return list;
    }

    // As wide as the longest title needs (plus room for the arrows), at
    // most as wide as the cascades get (longer names are elided)
    width: rowsLeft + iconLeft + iconSize + textSpacing + Math.min(Math.ceil(widestTitle), 380) + 32
    height: rows.implicitHeight

    property real widestTitle: 0
    function measure() {
        let widest = 0;
        entries.forEach(entry => {
            if (!entry.separator) {
                widest = Math.max(widest, metrics.advanceWidth(entry.title));
            }
        });
        for (let i = 0; i < pinnedRepeater.count; ++i) {
            const item = pinnedRepeater.itemAt(i);
            if (item) {
                widest = Math.max(widest, metrics.advanceWidth(item.title));
            }
        }
        widestTitle = widest;
    }
    onEntriesChanged: Qt.callLater(measure)
    Component.onCompleted: measure()

    function reset() {
        measure();
    }

    FontMetrics {
        id: metrics
        font.family: menu.xp.fontFamily
        font.pixelSize: menu.xp.fontPixelSize
    }

    // --- hover-to-open handling, as in StartMenu.qml ---
    property string hoverKind: ""
    property Item hoverItem: null

    function pointerElsewhere(item) {
        return hoverItem !== null && hoverItem !== item && hoverItem.hovered === true;
    }

    function hovered(kind, item) {
        hoverKind = kind;
        hoverItem = item;
        hoverTimer.restart();
    }

    Timer {
        id: hoverTimer
        interval: 350
        onTriggered: {
            // Only for the row still under the pointer (not one the pointer
            // crossed on its way into a cascade), and only while the menu is open
            if (!menu.controller.menuOpen || (menu.hoverItem && menu.hoverItem.hovered === false)) {
                return;
            }
            if (menu.hoverKind !== "" && menu.hoverKind === menu.openCascade) {
                return;
            }
            if (menu.hoverKind === "") {
                menu.controller.closeCascadesFrom(0);
            } else if (menu.controller.openOnHover) {
                menu.controller.openClassicMenu(menu.hoverKind, menu.hoverItem);
            }
        }
    }

    Keys.onEscapePressed: {
        const cascades = controller.cascades.length;
        if (cascades > 0) {
            controller.closeCascadesFrom(cascades - 1);
        } else {
            controller.closeMenu();
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: menu.controller.closeCascadesFrom(0)
    }

    // Banner: black, turning blue behind the text towards the bottom
    // (sampled from XP, measured from the bottom: blue from 217 px up)
    Rectangle {
        width: menu.xp.classicBannerWidth
        height: menu.height
        visible: !menu.smallIcons
        color: "#000000"
        clip: true

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.min(parent.height, 217)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#000000" }
                GradientStop { position: 16 / 217; color: "#00006f" }
                GradientStop { position: 56 / 217; color: "#0000b2" }
                GradientStop { position: 88 / 217; color: "#0000fa" }
                GradientStop { position: 160 / 217; color: "#0000fa" }
                GradientStop { position: 200 / 217; color: "#0000a0" }
                GradientStop { position: 1.0; color: "#000080" }
            }
        }

        // "Windows XP Professional", read from the bottom up, placed and
        // sized to match XP's (its first letter 12 px above the banner's
        // bottom, baseline 5 px from the right, words 10 px apart)
        Item {
            width: bannerRow.width
            height: bannerRow.height
            rotation: -90
            transformOrigin: Item.TopLeft
            x: parent.width - 5 - bannerTitle.baselineOffset
            y: parent.height - 10

            Row {
                id: bannerRow
                spacing: 10
                Text {
                    id: bannerTitle
                    text: menu.bannerTitle
                    renderType: Text.NativeRendering
                    font.family: menu.xp.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ffffff"
                }
                Text {
                    text: menu.bannerEdition
                    renderType: Text.NativeRendering
                    font.family: menu.xp.fontFamily
                    font.pixelSize: 16
                    color: "#ffffff"
                }
            }
        }
    }

    Column {
        id: rows
        x: menu.rowsLeft
        width: menu.width - menu.rowsLeft

        // Pinned programs at the top, like the shortcuts XP keeps there
        Repeater {
            id: pinnedRepeater
            model: menu.favoritesModel
            onCountChanged: Qt.callLater(menu.measure)

            delegate: MenuEntry {
                id: pinned

                required property int index
                required property var model

                width: rows.width
                height: menu.rowHeight
                xp: menu.xp
                iconSource: model.decoration
                iconSize: menu.iconSize
                leftPadding: menu.iconLeft
                textSpacing: menu.textSpacing
                title: model.display ?? ""
                dragUrl: model.url ?? ""
                dragController: menu.controller

                onHoveredChanged: if (hovered) menu.hovered("", pinned)
                onClicked: menu.controller.launchFavorite(index)
                onContextMenuRequested: (x, y) => menu.controller.showItemContextMenu(menu.favoritesModel, index, model.favoriteId ?? "", model.actionList, pinned, x, y)
            }
        }

        MenuSeparator {
            width: rows.width
            height: menu.xp.classicSeparatorHeight
            visible: pinnedRepeater.count > 0
        }

        Repeater {
            model: menu.entries

            delegate: Item {
                id: row

                required property var modelData

                width: rows.width
                height: modelData.separator ? menu.xp.classicSeparatorHeight : menu.rowHeight

                MenuSeparator {
                    anchors.fill: parent
                    visible: row.modelData.separator === true
                }

                MenuEntry {
                    id: rowEntry
                    anchors.fill: parent
                    visible: row.modelData.separator !== true
                    xp: menu.xp
                    iconSource: row.modelData.icon ?? ""
                    iconSize: menu.iconSize
                    leftPadding: menu.iconLeft
                    textSpacing: menu.textSpacing
                    title: row.modelData.title ?? ""
                    showArrow: row.modelData.arrow === true
                    forceHighlight: menu.openCascade !== "" && menu.openCascade === row.modelData.key
                        && !menu.pointerElsewhere(rowEntry)

                    onHoveredChanged: if (hovered) menu.hovered(row.modelData.arrow ? row.modelData.key : "", rowEntry)
                    onClicked: {
                        const key = row.modelData.key;
                        if (row.modelData.arrow) {
                            hoverTimer.stop();
                            if (menu.openCascade !== key) {
                                menu.controller.openClassicMenu(key, rowEntry);
                            }
                        } else if (key === "logoff") {
                            menu.controller.logOff();
                        } else if (key === "turnoff") {
                            menu.controller.turnOff();
                        } else {
                            menu.controller.openPlace(key);
                        }
                    }
                }
            }
        }
    }
}
