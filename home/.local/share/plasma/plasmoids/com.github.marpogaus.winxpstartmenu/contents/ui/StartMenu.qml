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
    // Keys of right-column entries to hide (see the places list below)
    property var hiddenPlaces: ["network", "connections", "admintools"]
    // Keys of right-column entries shown as a menu ("Display as a menu")
    property var menuPlaces: []

    property string userName
    property url userAvatar

    // "programs", "recent", a place key or "" – which cascade is attached to the menu.
    property string openCascade: ""

    property string searchText: ""
    property int searchIndex: 0
    readonly property bool searching: searchText.length > 0

    property var frequentItems: []

    readonly property int bodyHeight: Math.max(leftColumn.neededHeight, rightColumn.neededHeight, 330)

    // header | 1 px line | body | 1 px line | footer
    width: xp.menuWidth
    height: xp.headerHeight + 1 + bodyHeight + 1 + xp.footerHeight

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
            items.push({ row: i, display: o.display, decoration: o.decoration, favoriteId: o.favoriteId, actionList: o.actionList, url: o.url });
        }
        frequentItems = items;
    }

    // --- hover-to-open handling (XP opens cascades after a short delay) ---
    property string hoverKind: ""
    property Item hoverItem: null

    // The row whose cascade is open stays highlighted only while the
    // pointer is not on another row (XP moves the highlight at once, the
    // cascade follows after the delay)
    function pointerElsewhere(item) {
        return hoverItem !== null && hoverItem !== item && hoverItem.hovered === true;
    }

    function openKind(kind, item) {
        if (kind === "programs") {
            controller.openAllPrograms(item);
        } else if (kind === "recent") {
            controller.openRecentDocuments(item);
        } else {
            controller.openPlaceMenu(kind, item);
        }
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
            if (menu.hoverKind === menu.openCascade && menu.hoverKind !== "") {
                return;
            }
            if (menu.hoverKind === "") {
                menu.controller.closeCascadesFrom(0);
            } else if (!menu.controller.openOnHover) {
                // Without "Open submenus when I pause on them" only a click opens one
            } else {
                menu.openKind(menu.hoverKind, menu.hoverItem);
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
            readonly property url url: model.url ?? ""
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
            // Cascades never take focus, so Escape arrives here: close the
            // innermost cascade first, like XP, then the menu
            const cascades = controller.cascades.length;
            if (searching) {
                searchText = "";
            } else if (cascades > 0) {
                controller.closeCascadesFrom(cascades - 1);
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
            searchIndex = Math.max(0, Math.min(searchIndex + 1, searchList.count - 1));
        } else if (event.key === Qt.Key_Up && searching) {
            searchIndex = Math.max(searchIndex - 1, 0);
        } else if (modifiers === 0 && event.text.length > 0 && event.text.charCodeAt(0) >= 32
                   && event.text.charCodeAt(0) !== 127) { // Delete sends DEL (0x7f)
            searchText += event.text;
        } else {
            return;
        }
        event.accepted = true;
    }

    // Clicking empty space in the menu closes open cascades, like XP. Being
    // declared first, this area only gets clicks no item above it takes.
    MouseArea {
        anchors.fill: parent
        onPressed: menu.controller.closeCascadesFrom(0)
    }

    // ------------------------------------------------------------------
    // Frame. The window is transparent; the top corners are rounded by
    // clipping rounded rectangles that extend below the bottom edge.
    // Colours of header and footer are sampled row by row from XP.
    // ------------------------------------------------------------------
    Item {
        anchors.fill: parent
        clip: true

        // Blue frame behind everything (shows as the 2 px side borders)
        Rectangle {
            width: parent.width
            height: parent.height + menu.xp.cornerRadius
            radius: menu.xp.cornerRadius
            color: menu.xp.frame
        }

        // --------------------------------------------------------------
        // Header
        // --------------------------------------------------------------
        Item {
            id: header
            width: parent.width
            height: menu.xp.headerHeight
            clip: true

            Rectangle {
                width: parent.width
                height: parent.height + menu.xp.cornerRadius
                radius: menu.xp.cornerRadius
                // 64 rows + 6 hidden rows: position = row / 70
                gradient: Gradient {
                    GradientStop { position: 0 / 70; color: "#225cc5" }
                    GradientStop { position: 1 / 70; color: "#67a2e7" }
                    GradientStop { position: 2 / 70; color: "#75abe8" }
                    GradientStop { position: 3 / 70; color: "#397fd9" }
                    GradientStop { position: 4 / 70; color: "#1a69d2" }
                    GradientStop { position: 6 / 70; color: "#1464cd" }
                    GradientStop { position: 9 / 70; color: "#0e60cb" }
                    GradientStop { position: 11 / 70; color: "#0c5fcb" }
                    GradientStop { position: 14 / 70; color: "#0d60cb" }
                    GradientStop { position: 20 / 70; color: "#1164ce" }
                    GradientStop { position: 30 / 70; color: "#1b6cd3" }
                    GradientStop { position: 40 / 70; color: "#2577dc" }
                    GradientStop { position: 50 / 70; color: "#3383e5" }
                    GradientStop { position: 56 / 70; color: "#3d8ae8" }
                    GradientStop { position: 59 / 70; color: "#4692eb" }
                    GradientStop { position: 1.0; color: "#4792ec" }
                }
            }

            // Light bevel and glow on the left edge
            Rectangle {
                x: 1
                y: 3
                width: 1
                height: parent.height - 3
                color: "#7493da"
            }
            Rectangle {
                x: 2
                y: 3
                width: 7
                height: parent.height - 3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.28) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
            // Shading on the right edge
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 1
                y: 3
                width: 8
                height: parent.height - 3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0.1, 0.35, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0.1, 0.35, 0.22) }
                }
            }
        }

        // User picture: 48 x 48 in a 2 px light rounded frame with a soft
        // shadow to the right and below
        Rectangle {
            x: avatarFrame.x + 2
            y: avatarFrame.y + 2
            width: avatarFrame.width
            height: avatarFrame.height
            radius: avatarFrame.radius
            color: Qt.rgba(0, 0.05, 0.25, 0.3)
        }
        Rectangle {
            id: avatarFrame
            x: 7
            y: 7
            width: 52
            height: 52
            radius: 4
            color: "#c5d2ec"
            border.width: 1
            border.color: "#d5dcea"

            Item {
                x: 2
                y: 2
                width: 48
                height: 48
                clip: true

                Image {
                    id: avatar
                    anchors.fill: parent
                    source: menu.userAvatar
                    sourceSize: Qt.size(96, 96)
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
            x: avatarFrame.x + avatarFrame.width + 8 + 1
            anchors.verticalCenter: avatarFrame.verticalCenter
            anchors.verticalCenterOffset: 2
            width: parent.width - x - 10
            text: menu.userName
            textFormat: Text.PlainText
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font.family: menu.xp.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: Qt.rgba(0, 0, 0, 0.4)
        }
        Text {
            x: avatarFrame.x + avatarFrame.width + 8
            anchors.verticalCenter: avatarFrame.verticalCenter
            width: parent.width - x - 10
            text: menu.userName
            textFormat: Text.PlainText
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font.family: menu.xp.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: "#ffffff"
        }

        // Dark rule between header and body
        Rectangle {
            x: 1
            y: menu.xp.headerHeight
            width: parent.width - 2
            height: 1
            color: menu.xp.bodyTopLine
        }

        // --------------------------------------------------------------
        // Body
        // --------------------------------------------------------------
        Item {
            id: body
            x: menu.xp.frameWidth
            y: menu.xp.headerHeight + 1
            width: parent.width - 2 * menu.xp.frameWidth
            height: menu.bodyHeight

            // ---------------- left column: programs ----------------
            Rectangle {
                id: leftColumn

                readonly property int neededHeight: 5 + leftTop.implicitHeight + allProgramsSeparator.height + 2 + allPrograms.height + 6

                width: menu.xp.leftWidth
                height: parent.height
                color: menu.xp.leftBackground

                // XP's faint blue tint along the left edge (4 px)
                Rectangle {
                    width: 4
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#e6edf8" }
                        GradientStop { position: 1.0; color: "#f1f4f9" }
                    }
                }

                Column {
                    id: leftTop
                    x: 2
                    y: 5
                    width: parent.width - 4
                    visible: !menu.searching

                    Repeater {
                        model: menu.favoritesModel

                        delegate: MenuEntry {
                            id: pinned

                            required property int index
                            required property var model

                            readonly property string favoriteId: model.favoriteId ?? ""
                            dragUrl: model.url ?? ""
                            dragController: menu.controller
                            readonly property string specialTitle: favoriteId === "preferred://browser" ? i18n("Internet")
                                                                 : favoriteId === "preferred://mail" ? i18n("E-mail") : ""

                            width: leftTop.width
                            height: menu.xp.programRowHeight
                            xp: menu.xp
                            iconSource: model.decoration
                            iconSize: menu.xp.programIconSize
                            leftPadding: 3
                            textSpacing: 3
                            title: specialTitle || (model.display ?? "")
                            // Small icons leave no room for the program's name
                            subtitle: specialTitle && !menu.xp.smallIcons ? (model.display ?? "") : ""
                            bold: true

                            onHoveredChanged: if (hovered) menu.hovered("", pinned)
                            onClicked: menu.controller.launchFavorite(index)
                            onContextMenuRequested: (x, y) => menu.controller.showItemContextMenu(menu.favoritesModel, index, favoriteId, model.actionList, pinned, x, y)
                        }
                    }

                    MenuSeparator {
                        width: parent.width
                        height: menu.xp.separatorHeight
                        leftInset: 2
                        rightInset: 6
                        color: menu.xp.leftSeparator
                        visible: menu.frequentItems.length > 0
                    }

                    Repeater {
                        model: menu.frequentItems

                        delegate: MenuEntry {
                            id: frequent

                            required property var modelData

                            dragUrl: modelData.url ?? ""
                            dragController: menu.controller
                            width: leftTop.width
                            height: menu.xp.programRowHeight
                            xp: menu.xp
                            iconSource: modelData.decoration
                            iconSize: menu.xp.programIconSize
                            leftPadding: 3
                            textSpacing: 3
                            title: modelData.display
                            // XP breaks long names onto two lines at about 105 px
                            wrap: !menu.xp.smallIcons
                            wrapWidth: 105

                            onHoveredChanged: if (hovered) menu.hovered("", frequent)
                            onClicked: menu.controller.launchFrequent(modelData.row)
                            onContextMenuRequested: (x, y) => menu.controller.showItemContextMenu(menu.frequentModel, modelData.row, modelData.favoriteId, modelData.actionList, frequent, x, y)
                        }
                    }
                }

                // Search results replace the program lists while typing
                Item {
                    x: 2
                    y: 5
                    width: parent.width - 4
                    height: allProgramsSeparator.y - y
                    visible: menu.searching

                    Item {
                        id: searchHeader
                        width: parent.width
                        height: 24

                        Kirigami.Icon {
                            id: searchIcon
                            x: 8
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
                        height: menu.xp.separatorHeight
                        leftInset: 2
                        rightInset: 6
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

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: MenuEntry {
                            id: result

                            required property int index
                            required property var model

                            width: searchList.width
                            height: menu.xp.placeRowHeight
                            xp: menu.xp
                            iconSource: model.decoration
                            title: model.display ?? ""
                            iconSize: menu.xp.placeIconSize
                            leftPadding: 7
                            textSpacing: 9
                            forceHighlight: index === menu.searchIndex

                            onHoveredChanged: if (hovered) menu.searchIndex = index
                            onClicked: menu.controller.launchSearchResult(index)
                            onContextMenuRequested: (x, y) => menu.controller.showItemContextMenu(menu.searchModel, index, model.favoriteId ?? "", model.actionList, result, x, y)
                        }
                    }

                    MenuEntry {
                        anchors.top: searchSeparator.bottom
                        width: parent.width
                        height: 24
                        visible: searchList.count === 0
                        xp: menu.xp
                        iconSize: 0
                        leftPadding: 40
                        textSpacing: 0
                        title: i18n("No items match your search.")
                        interactive: false
                    }
                }

                MenuSeparator {
                    id: allProgramsSeparator
                    x: 2
                    anchors.bottom: allPrograms.top
                    anchors.bottomMargin: 2
                    width: parent.width - 4
                    height: menu.xp.separatorHeight
                    leftInset: 2
                    rightInset: 6
                    color: menu.xp.leftSeparator
                }

                // "All Programs ▶": as wide as the column, label and arrow
                // centred; the menu opens right after it
                Item {
                    id: allPrograms

                    readonly property bool hovered: allProgramsMouse.containsMouse
                    readonly property bool highlighted: hovered
                        || (menu.openCascade === "programs" && !menu.pointerElsewhere(allPrograms))

                    // XP: 4 px from the column's left, 6 px from its right and bottom
                    x: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    width: parent.width - 10
                    height: 24

                    Rectangle {
                        anchors.fill: parent
                        color: menu.xp.highlight
                        visible: allPrograms.highlighted
                    }

                    Text {
                        id: allProgramsLabel
                        x: Math.round((allPrograms.width - width - 18 - allProgramsArrow.width) / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n("All Programs")
                        renderType: Text.NativeRendering
                        font.family: menu.xp.fontFamily
                        font.pixelSize: menu.xp.fontPixelSize
                        font.bold: true
                        color: allPrograms.highlighted ? menu.xp.highlightText : menu.xp.leftText
                    }
                    Image {
                        id: allProgramsArrow
                        anchors.left: allProgramsLabel.right
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        source: "../images/all-programs.svg"
                        sourceSize: Qt.size(17, 22)
                    }

                    MouseArea {
                        id: allProgramsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: if (containsMouse) menu.hovered("programs", allPrograms)
                        onClicked: {
                            hoverTimer.stop();
                            if (menu.openCascade !== "programs") {
                                menu.openKind("programs", allPrograms);
                            }
                        }
                    }
                }
            }

            // Divider between the columns
            Rectangle {
                x: leftColumn.width
                width: 1
                height: parent.height
                color: menu.xp.rightBorder
            }

            // ---------------- right column: places ----------------
            Rectangle {
                id: rightColumn

                readonly property int neededHeight: 5 + placesColumn.implicitHeight + 6

                x: leftColumn.width + 1
                width: menu.xp.rightWidth
                height: parent.height
                color: menu.xp.rightBackground

                // XP darkens the column's last 3 px towards the frame
                Row {
                    anchors.right: parent.right
                    height: parent.height
                    Repeater {
                        model: menu.xp.rightEdgeShade
                        Rectangle {
                            required property color modelData
                            width: 1
                            height: parent.height
                            color: modelData
                        }
                    }
                }

                Column {
                    id: placesColumn
                    x: 2
                    y: 5
                    width: parent.width - 4

                    Repeater {
                        model: [
                            { key: "documents", icon: "folder-documents", title: i18n("My Documents"), bold: true },
                            { key: "recent", icon: "document-open-recent", title: i18n("My Recent Documents"), bold: true, arrow: true },
                            { key: "pictures", icon: "folder-pictures", title: i18n("My Pictures"), bold: true },
                            { key: "music", icon: "folder-music", title: i18n("My Music"), bold: true },
                            { key: "computer", icon: "computer", title: i18n("My Computer"), bold: true },
                            { key: "network", icon: "network-workgroup", title: i18n("My Network Places"), bold: true },
                            { separator: true },
                            { key: "controlpanel", icon: "preferences-system", title: i18n("Control Panel") },
                            { key: "admintools", icon: "applications-system", title: i18n("Administrative Tools"), arrow: true },
                            { key: "defaults", icon: "preferences-desktop-default-applications", title: i18n("Set Program Access and Defaults") },
                            { key: "connections", icon: "network-wired", title: i18n("Network Connections") },
                            { key: "printers", icon: "printer", title: i18n("Printers and Faxes") },
                            { separator: true },
                            { key: "help", icon: "help-browser", title: i18n("Help and Support") },
                            { key: "search", icon: "system-search", title: i18n("Search") },
                            { key: "run", icon: "system-run", title: i18n("Run...") }
                        ]

                        delegate: Item {
                            id: place

                            required property var modelData
                            readonly property bool hidden: !modelData.separator && menu.hiddenPlaces.indexOf(modelData.key) >= 0
                            // Opens a cascade instead of a window
                            readonly property bool cascades: modelData.arrow === true || menu.menuPlaces.indexOf(modelData.key) >= 0

                            width: placesColumn.width
                            height: hidden ? 0
                                  : modelData.separator ? menu.xp.separatorHeight
                                  : Math.max(menu.xp.placeRowHeight, placeEntry.labelsHeight + 8)
                            visible: !hidden

                            MenuSeparator {
                                anchors.fill: parent
                                visible: place.modelData.separator === true
                                leftInset: 52
                                rightInset: 56
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
                                showArrow: place.cascades
                                wrap: true
                                iconSize: menu.xp.placeIconSize
                                leftPadding: 5
                                textSpacing: 3
                                textColor: menu.xp.rightText
                                forceHighlight: place.cascades && menu.openCascade === place.modelData.key
                                    && !menu.pointerElsewhere(placeEntry)

                                onHoveredChanged: if (hovered) menu.hovered(place.cascades ? place.modelData.key : "", placeEntry)
                                onClicked: {
                                    if (place.cascades) {
                                        hoverTimer.stop();
                                        if (menu.openCascade !== place.modelData.key) {
                                            menu.openKind(place.modelData.key, placeEntry);
                                        }
                                    } else {
                                        menu.controller.openPlace(place.modelData.key);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Orange line under the header, drawn over both columns
            Rectangle {
                width: parent.width
                height: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    // Measured on XP: fades in over 10-30 %, solid to 58 %,
                    // then turns grey by 87 %
                    GradientStop { position: 0.10; color: Qt.rgba(0.918, 0.592, 0.212, 0) }
                    GradientStop { position: 0.30; color: menu.xp.orange }
                    GradientStop { position: 0.58; color: menu.xp.orange }
                    GradientStop { position: 0.87; color: "#d6d6d3" }
                    GradientStop { position: 1.0; color: "#d6d6d3" }
                }
            }
        }

        // Rule between body and footer
        Rectangle {
            x: 1
            y: body.y + body.height
            width: parent.width - 2
            height: 1
            color: menu.xp.bodyBottomLine
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
                GradientStop { position: 0 / 39; color: "#438be3" }
                GradientStop { position: 3 / 39; color: "#438be4" }
                GradientStop { position: 6 / 39; color: "#3e89e4" }
                GradientStop { position: 10 / 39; color: "#3683e4" }
                GradientStop { position: 15 / 39; color: "#2d7de2" }
                GradientStop { position: 20 / 39; color: "#2274de" }
                GradientStop { position: 25 / 39; color: "#196ddb" }
                GradientStop { position: 30 / 39; color: "#1568d6" }
                GradientStop { position: 35 / 39; color: "#1062cf" }
                GradientStop { position: 37 / 39; color: "#0d5bc7" }
                GradientStop { position: 1.0; color: "#0c56c0" }
            }

            // Edge shading (darker towards the outline on both sides)
            Rectangle {
                x: 1
                width: 1
                height: parent.height
                color: Qt.rgba(0.08, 0.12, 0.5, 0.35)
            }
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 1
                width: 5
                height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0.1, 0.35, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0.1, 0.35, 0.25) }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

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

        // Side frame of the body: the outline plus one inner pixel
        Rectangle {
            x: 1
            y: body.y
            width: 1
            height: body.height
            color: menu.xp.frameInnerLeft
        }
        Rectangle {
            x: parent.width - 2
            y: body.y
            width: 1
            height: body.height
            color: menu.xp.frameInnerRight
        }

        // 1 px outline around the whole menu
        Rectangle {
            width: parent.width
            height: parent.height + menu.xp.cornerRadius
            radius: menu.xp.cornerRadius
            color: "transparent"
            border.width: 1
            border.color: menu.xp.frameOutline
        }
    }

    component FooterButton: Item {
        id: footerButton

        readonly property bool hovered: footerMouse.containsMouse
        property url iconSource
        property string text

        signal clicked()

        width: footerRow.width + 6
        height: 30

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
            anchors.verticalCenterOffset: footerMouse.pressed ? 1 : 0
            spacing: 6

            Image {
                anchors.verticalCenter: parent.verticalCenter
                source: footerButton.iconSource
                sourceSize: Qt.size(24, 24)
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
