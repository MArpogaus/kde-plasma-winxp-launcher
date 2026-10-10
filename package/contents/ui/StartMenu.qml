/*
    SPDX-License-Identifier: GPL-2.0-or-later

    The Windows XP (Luna) start menu: blue header with the user picture,
    white program column on the left, light blue places column on the
    right and the Log Off / Turn Off Computer footer.

    All behaviour is delegated to `controller` (main.qml) so this file
    only depends on QtQuick and Kirigami.
*/
import QtQuick
import org.kde.kirigami as Kirigami

FocusScope {
    id: menu

    required property QtObject xp
    required property QtObject controller

    property var favoritesModel: null
    property var frequentModel: null
    property var searchModel: null
    property int numFrequentApps: 6
    property bool showNetworkPlaces: true

    property string userName
    property url userAvatar

    // "programs", "recent" or "" – which cascade is attached to the menu.
    property string openCascade: ""

    property string searchText: ""
    property int searchIndex: 0
    readonly property bool searching: searchText.length > 0

    property var frequentItems: []

    readonly property int screenHeight: Screen.height
    readonly property int bodyHeight: Math.max(leftColumn.neededHeight, rightColumn.neededHeight, 330)

    width: xp.menuWidth
    height: xp.headerHeight + 2 + bodyHeight + xp.footerHeight

    onSearchTextChanged: searchIndex = 0

    function reset() {
        searchText = "";
        searchIndex = 0;
        rebuildFrequent();
    }

    function rebuildFrequent() {
        const items = [];
        for (let i = 0; i < frequentCollector.count && items.length < numFrequentApps; ++i) {
            const o = frequentCollector.objectAt(i);
            if (!o || controller.isPinned(o.favoriteId)) {
                continue;
            }
            items.push({ row: i, display: o.display, decoration: o.decoration, favoriteId: o.favoriteId, actionList: o.actionList });
        }
        frequentItems = items;
    }

    // --- hover-to-open handling (XP opens cascades after a short delay) ---
    property string hoverKind: ""
    property Item hoverItem: null

    function hovered(kind, item) {
        hoverKind = kind;
        hoverItem = item;
        hoverTimer.restart();
    }

    Timer {
        id: hoverTimer
        interval: 350
        onTriggered: {
            if (menu.hoverKind === menu.openCascade && menu.hoverKind !== "") {
                return;
            }
            if (menu.hoverKind === "programs") {
                menu.controller.openAllPrograms(menu.hoverItem);
            } else if (menu.hoverKind === "recent") {
                menu.controller.openRecentDocuments(menu.hoverItem);
            } else {
                menu.controller.closeCascadesFrom(0);
            }
        }
    }

    Instantiator {
        id: frequentCollector
        model: menu.frequentModel
        delegate: QtObject {
            required property var model
            readonly property string display: model.display ?? ""
            readonly property var decoration: model.decoration
            readonly property string favoriteId: model.favoriteId ?? ""
            readonly property var actionList: model.actionList
        }
        onObjectAdded: rebuildTimer.restart()
        onObjectRemoved: rebuildTimer.restart()
    }

    Connections {
        target: menu.favoritesModel
        ignoreUnknownSignals: true
        function onCountChanged() {
            rebuildTimer.restart();
        }
    }

    Timer {
        id: rebuildTimer
        interval: 0
        onTriggered: menu.rebuildFrequent()
    }

    onNumFrequentAppsChanged: rebuildTimer.restart()

    // --- keyboard: type to search, XP had no search box ---
    Keys.onPressed: event => {
        const modifiers = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
        if (event.key === Qt.Key_Escape) {
            if (searching) {
                searchText = "";
            } else {
                controller.closeMenu();
            }
        } else if (event.key === Qt.Key_Backspace) {
            searchText = searchText.slice(0, -1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (searching && searchList.count > 0) {
                controller.launchSearchResult(searchIndex);
            }
        } else if (event.key === Qt.Key_Down && searching) {
            searchIndex = Math.min(searchIndex + 1, searchList.count - 1);
        } else if (event.key === Qt.Key_Up && searching) {
            searchIndex = Math.max(searchIndex - 1, 0);
        } else if (modifiers === 0 && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            searchText += event.text;
        } else {
            return;
        }
        event.accepted = true;
    }

    // ------------------------------------------------------------------
    // Frame. The window is transparent; the top corners are rounded by
    // clipping a rounded rectangle that extends below the bottom edge.
    // ------------------------------------------------------------------
    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            width: parent.width
            height: parent.height + menu.xp.cornerRadius
            radius: menu.xp.cornerRadius
            color: menu.xp.frame
        }

        // Header
        Rectangle {
            id: header
            width: parent.width
            height: menu.xp.headerHeight + menu.xp.cornerRadius
            radius: menu.xp.cornerRadius
            gradient: Gradient {
                GradientStop { position: 0.00; color: "#1868ce" }
                GradientStop { position: 0.12; color: "#0e60cb" }
                GradientStop { position: 0.20; color: "#0e60cb" }
                GradientStop { position: 0.32; color: "#1164cf" }
                GradientStop { position: 0.33; color: "#1667cf" }
                GradientStop { position: 0.47; color: "#1b6cd3" }
                GradientStop { position: 0.54; color: "#1e70d9" }
                GradientStop { position: 0.60; color: "#2476dc" }
                GradientStop { position: 0.65; color: "#297ae0" }
                GradientStop { position: 0.77; color: "#3482e3" }
                GradientStop { position: 0.79; color: "#3786e5" }
                GradientStop { position: 0.90; color: "#428ee9" }
                GradientStop { position: 1.00; color: "#4791eb" }
            }
        }

        // User picture
        Rectangle {
            id: avatarFrame
            x: 5
            anchors.verticalCenter: parent.top
            anchors.verticalCenterOffset: menu.xp.headerHeight / 2
            width: 46
            height: 46
            radius: 3
            color: Qt.rgba(222 / 255, 222 / 255, 222 / 255, 0.8)

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 2
                color: "#ffffff"
                clip: true

                Image {
                    id: avatar
                    anchors.fill: parent
                    source: menu.userAvatar
                    sourceSize: Qt.size(84, 84)
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: status === Image.Ready
                }

                Kirigami.Icon {
                    anchors.fill: parent
                    visible: avatar.status !== Image.Ready
                    source: "user-identity"
                    roundToIconSize: false
                }
            }
        }

        Text {
            x: avatarFrame.x + avatarFrame.width + 6 + 1
            anchors.verticalCenter: avatarFrame.verticalCenter
            anchors.verticalCenterOffset: 1
            width: parent.width - x - 8
            text: menu.userName
            textFormat: Text.PlainText
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font.family: menu.xp.fontFamily
            font.pixelSize: 14
            font.bold: true
            color: Qt.rgba(0, 0, 0, 0.7)
        }
        Text {
            x: avatarFrame.x + avatarFrame.width + 6
            anchors.verticalCenter: avatarFrame.verticalCenter
            width: parent.width - x - 8
            text: menu.userName
            textFormat: Text.PlainText
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font.family: menu.xp.fontFamily
            font.pixelSize: 14
            font.bold: true
            color: "#ffffff"
        }

        // Light inner outline around the whole frame
        Rectangle {
            width: parent.width
            height: parent.height + menu.xp.cornerRadius
            radius: menu.xp.cornerRadius
            color: "transparent"
            border.width: 1
            border.color: menu.xp.frameHighlight
        }

        // --------------------------------------------------------------
        // Body
        // --------------------------------------------------------------
        Item {
            id: body
            x: 2
            y: menu.xp.headerHeight
            width: parent.width - 4
            height: menu.bodyHeight + 2

            // Orange line under the header
            Rectangle {
                width: parent.width
                height: 2
                color: "#385de7"
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(0.855, 0.533, 0.290, 0) }
                        GradientStop { position: 0.5; color: menu.xp.orange }
                        GradientStop { position: 1.0; color: Qt.rgba(0.855, 0.533, 0.290, 0) }
                    }
                }
            }

            // ---------------- left column: programs ----------------
            Rectangle {
                id: leftColumn

                readonly property int neededHeight: 6 + leftTop.implicitHeight + allProgramsSeparator.height + allPrograms.height + 6

                y: 2
                width: menu.xp.leftWidth
                height: parent.height - 2
                color: menu.xp.leftBackground

                Column {
                    id: leftTop
                    x: 5
                    y: 6
                    width: parent.width - 10
                    spacing: 2
                    visible: !menu.searching

                    Repeater {
                        model: menu.favoritesModel

                        delegate: MenuEntry {
                            id: pinned

                            required property int index
                            required property var model

                            readonly property string favoriteId: model.favoriteId ?? ""
                            readonly property string specialTitle: favoriteId === "preferred://browser" ? i18n("Internet")
                                                                 : favoriteId === "preferred://mail" ? i18n("E-mail") : ""

                            width: leftTop.width
                            height: 34
                            xp: menu.xp
                            iconSource: model.decoration
                            title: specialTitle || (model.display ?? "")
                            subtitle: specialTitle ? (model.display ?? "") : ""
                            bold: true

                            onHoveredChanged: if (hovered) menu.hovered("", pinned)
                            onClicked: menu.controller.launchFavorite(index)
                            onContextMenuRequested: (x, y) => menu.controller.showItemContextMenu(menu.favoritesModel, index, favoriteId, model.actionList, pinned, x, y)
                        }
                    }

                    MenuSeparator {
                        width: parent.width
                        color: menu.xp.leftSeparator
                        visible: menu.frequentItems.length > 0
                    }

                    Repeater {
                        model: menu.frequentItems

                        delegate: MenuEntry {
                            id: frequent

                            required property var modelData

                            width: leftTop.width
                            height: 34
                            xp: menu.xp
                            iconSource: modelData.decoration
                            title: modelData.display

                            onHoveredChanged: if (hovered) menu.hovered("", frequent)
                            onClicked: menu.controller.launchFrequent(modelData.row)
                            onContextMenuRequested: (x, y) => menu.controller.showItemContextMenu(menu.frequentModel, modelData.row, modelData.favoriteId, modelData.actionList, frequent, x, y)
                        }
                    }
                }

                // Search results replace the program lists while typing
                Item {
                    id: searchPane
                    x: 5
                    y: 6
                    width: parent.width - 10
                    height: allProgramsSeparator.y - y
                    visible: menu.searching

                    Item {
                        id: searchHeader
                        width: parent.width
                        height: 22

                        Kirigami.Icon {
                            id: searchIcon
                            x: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            source: "edit-find"
                            roundToIconSize: false
                        }
                        Text {
                            id: queryText
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, parent.width - x - 6)
                            text: menu.searchText
                            textFormat: Text.PlainText
                            elide: Text.ElideLeft
                            renderType: Text.NativeRendering
                            font.family: menu.xp.fontFamily
                            font.pixelSize: menu.xp.fontPixelSize
                            font.bold: true
                        }
                        Rectangle {
                            anchors.left: queryText.right
                            anchors.leftMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 13
                            color: "#000000"

                            SequentialAnimation on opacity {
                                running: menu.searching
                                loops: Animation.Infinite
                                PropertyAction { value: 1 }
                                PauseAnimation { duration: 530 }
                                PropertyAction { value: 0 }
                                PauseAnimation { duration: 530 }
                            }
                        }
                    }

                    MenuSeparator {
                        id: searchSeparator
                        anchors.top: searchHeader.bottom
                        width: parent.width
                        color: menu.xp.leftSeparator
                    }

                    ListView {
                        id: searchList
                        anchors.top: searchSeparator.bottom
                        anchors.bottom: parent.bottom
                        width: parent.width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: menu.searching ? menu.searchModel : null
                        currentIndex: menu.searchIndex
                        spacing: 1

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: MenuEntry {
                            id: result

                            required property int index
                            required property var model

                            width: searchList.width
                            height: 28
                            xp: menu.xp
                            iconSource: model.decoration
                            title: model.display ?? ""
                            iconSize: 24
                            forceHighlight: index === menu.searchIndex

                            onHoveredChanged: if (hovered) menu.searchIndex = index
                            onClicked: menu.controller.launchSearchResult(index)
                            onContextMenuRequested: (x, y) => menu.controller.showItemContextMenu(menu.searchModel, index, model.favoriteId ?? "", model.actionList, result, x, y)
                        }
                    }

                    MenuEntry {
                        anchors.top: searchSeparator.bottom
                        width: parent.width
                        height: 22
                        visible: searchList.count === 0
                        xp: menu.xp
                        iconSize: 0
                        leftPadding: 4
                        title: i18n("No items match your search.")
                        interactive: false
                    }
                }

                MenuSeparator {
                    id: allProgramsSeparator
                    x: 5
                    anchors.bottom: allPrograms.top
                    width: parent.width - 10
                    color: menu.xp.leftSeparator
                }

                // "All Programs ▶"
                Item {
                    id: allPrograms

                    readonly property bool highlighted: allProgramsMouse.containsMouse || menu.openCascade === "programs"

                    x: 5
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    width: parent.width - 10
                    height: 26

                    Rectangle {
                        anchors.fill: parent
                        color: menu.xp.highlight
                        visible: allPrograms.highlighted
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n("All Programs")
                            renderType: Text.NativeRendering
                            font.family: menu.xp.fontFamily
                            font.pixelSize: menu.xp.fontPixelSize
                            font.bold: true
                            color: allPrograms.highlighted ? menu.xp.highlightText : menu.xp.leftText
                        }
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "../images/all-programs.svg"
                            sourceSize: Qt.size(18, 18)
                        }
                    }

                    MouseArea {
                        id: allProgramsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: if (containsMouse) menu.hovered("programs", allPrograms)
                        onClicked: {
                            hoverTimer.stop();
                            if (menu.openCascade !== "programs") {
                                menu.controller.openAllPrograms(allPrograms);
                            }
                        }
                    }
                }
            }

            // ---------------- right column: places ----------------
            Rectangle {
                id: rightColumn

                readonly property int neededHeight: 6 + placesColumn.implicitHeight + 6

                x: leftColumn.width
                y: 2
                width: parent.width - leftColumn.width
                height: parent.height - 2
                color: menu.xp.rightBackground

                Rectangle {
                    width: 1
                    height: parent.height
                    color: menu.xp.rightBorder
                }

                Column {
                    id: placesColumn
                    x: 6
                    y: 6
                    width: parent.width - 11

                    Repeater {
                        model: [
                            { key: "documents", icon: "folder-documents", title: i18n("My Documents"), bold: true },
                            { key: "recent", icon: "document-open-recent", title: i18n("My Recent Documents"), bold: true, arrow: true },
                            { key: "pictures", icon: "folder-pictures", title: i18n("My Pictures"), bold: true },
                            { key: "music", icon: "folder-music", title: i18n("My Music"), bold: true },
                            { key: "computer", icon: "computer", title: i18n("My Computer"), bold: true },
                            { key: "network", icon: "network-workgroup", title: i18n("My Network Places"), bold: true, hidden: !menu.showNetworkPlaces },
                            { separator: true },
                            { key: "controlpanel", icon: "preferences-system", title: i18n("Control Panel") },
                            { key: "defaults", icon: "preferences-desktop-default-applications", title: i18n("Set Program Access and Defaults") },
                            { key: "printers", icon: "printer", title: i18n("Printers and Faxes") },
                            { separator: true },
                            { key: "help", icon: "help-browser", title: i18n("Help and Support") },
                            { key: "search", icon: "system-search", title: i18n("Search") },
                            { key: "run", icon: "system-run", title: i18n("Run...") }
                        ]

                        delegate: Item {
                            id: place

                            required property var modelData

                            width: placesColumn.width
                            height: modelData.hidden ? 0 : (modelData.separator ? 9 : Math.max(26, placeEntry.labelsHeight + 6))
                            visible: !modelData.hidden

                            MenuSeparator {
                                anchors.fill: parent
                                visible: place.modelData.separator === true
                                color: menu.xp.rightSeparator
                            }

                            MenuEntry {
                                id: placeEntry
                                anchors.fill: parent
                                visible: place.modelData.separator !== true
                                xp: menu.xp
                                iconSource: place.modelData.icon ?? ""
                                title: place.modelData.title ?? ""
                                bold: place.modelData.bold === true
                                showArrow: place.modelData.arrow === true
                                wrap: true
                                iconSize: 22
                                leftPadding: 2
                                textSpacing: 5
                                textColor: menu.xp.rightText
                                forceHighlight: place.modelData.key === "recent" && menu.openCascade === "recent"

                                onHoveredChanged: if (hovered) menu.hovered(place.modelData.key === "recent" ? "recent" : "", placeEntry)
                                onClicked: {
                                    if (place.modelData.key === "recent") {
                                        hoverTimer.stop();
                                        menu.controller.openRecentDocuments(placeEntry);
                                    } else {
                                        menu.controller.openPlace(place.modelData.key);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --------------------------------------------------------------
        // Footer
        // --------------------------------------------------------------
        Rectangle {
            id: footer
            anchors.bottom: parent.bottom
            width: parent.width
            height: menu.xp.footerHeight
            gradient: Gradient {
                GradientStop { position: 0.00; color: "#4282d6" }
                GradientStop { position: 0.03; color: "#3b85e0" }
                GradientStop { position: 0.05; color: "#418ae3" }
                GradientStop { position: 0.17; color: "#418ae3" }
                GradientStop { position: 0.21; color: "#3c87e2" }
                GradientStop { position: 0.26; color: "#3786e4" }
                GradientStop { position: 0.29; color: "#3482e3" }
                GradientStop { position: 0.39; color: "#2e7ee1" }
                GradientStop { position: 0.49; color: "#2374df" }
                GradientStop { position: 0.57; color: "#2072db" }
                GradientStop { position: 0.62; color: "#196edb" }
                GradientStop { position: 0.72; color: "#176bd8" }
                GradientStop { position: 0.75; color: "#1468d7" }
                GradientStop { position: 0.83; color: "#1165d6" }
                GradientStop { position: 0.88; color: "#0f61cb" }
                GradientStop { position: 1.00; color: "#0f61cb" }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                FooterButton {
                    iconSource: "../images/log-off.svg"
                    text: i18n("Log Off")
                    onClicked: menu.controller.logOff()
                }
                FooterButton {
                    iconSource: "../images/turn-off.svg"
                    text: i18n("Turn Off Computer")
                    onClicked: menu.controller.turnOff()
                }
            }
        }
    }

    component FooterButton: Item {
        id: footerButton

        property url iconSource
        property string text

        signal clicked()

        width: footerRow.width + 6
        height: 28

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: Qt.rgba(1, 1, 1, footerMouse.pressed ? 0.05 : 0.12)
            visible: footerMouse.containsMouse
        }

        Row {
            id: footerRow
            x: 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Image {
                anchors.verticalCenter: parent.verticalCenter
                source: footerButton.iconSource
                sourceSize: Qt.size(22, 22)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: footerButton.text
                renderType: Text.NativeRendering
                font.family: menu.xp.fontFamily
                font.pixelSize: menu.xp.fontPixelSize
                color: "#ffffff"
            }
        }

        MouseArea {
            id: footerMouse
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: if (containsMouse) menu.hovered("", footerButton)
            onClicked: footerButton.clicked()
        }
    }
}
