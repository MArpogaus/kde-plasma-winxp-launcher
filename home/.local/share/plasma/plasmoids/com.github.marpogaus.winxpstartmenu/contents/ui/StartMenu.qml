/*
    SPDX-License-Identifier: GPL-2.0-or-later

    The Windows XP start menu: header with the user picture, programs on
    the left, places on the right and the Log Off / Turn Off Computer
    footer, in the Plasma theme's dialog frame, lines and colours.

    All behaviour is delegated to `controller` (main.qml) so this file
    only depends on QtQuick, Kirigami and KSvg.
*/
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

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

    // XP's own frame from the Plasma theme (widgets/winxp, startmenu-*):
    // header, columns and footer with a 2 px frame. Without it the window
    // shows the theme's dialog frame and lines separate the parts.
    KSvg.Svg {
        id: winxp
        imagePath: "widgets/winxp"
        // Checked again when the Plasma theme changes
        property bool present: hasElement("startmenu-header")
        onRepaintNeeded: present = hasElement("startmenu-header")
    }
    readonly property bool xpChrome: winxp.present
    readonly property int frameWidth: xpChrome ? 2 : 0

    // header | 1 px line | body | 1 px line | footer
    width: frameWidth + xp.leftWidth + 1 + xp.rightWidth + frameWidth
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
    // XP's frame (header with the orange line, the columns' background
    // and the footer) or, without it, the theme's lines between the parts
    // ------------------------------------------------------------------
    Item {
        anchors.fill: parent

        KSvg.SvgItem {
            visible: menu.xpChrome
            width: parent.width
            height: naturalSize.height
            svg: winxp
            elementId: "startmenu-header"
        }
        KSvg.SvgItem {
            visible: menu.xpChrome
            y: menu.xp.headerHeight + 3
            width: parent.width
            height: menu.bodyHeight - 2
            svg: winxp
            elementId: "startmenu-body"
        }
        KSvg.SvgItem {
            visible: menu.xpChrome
            anchors.bottom: parent.bottom
            width: parent.width
            height: naturalSize.height
            svg: winxp
            elementId: "startmenu-footer"
        }

        // --------------------------------------------------------------
        // Header: user picture and name
        // --------------------------------------------------------------
        // XP's frame around the picture is part of the header
        Item {
            id: avatarFrame
            x: 7
            y: 7
            width: 52
            height: 52

            Image {
                id: avatar
                anchors.fill: parent
                anchors.margins: 2
                source: menu.userAvatar
                sourceSize: Qt.size(96, 96)
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: status === Image.Ready
            }

            Kirigami.Icon {
                anchors.fill: parent
                anchors.margins: 2
                visible: avatar.status !== Image.Ready
                source: "user-identity"
                roundToIconSize: false
            }
        }

        // On XP's blue header: white with a soft shadow
        Text {
            visible: menu.xpChrome
            x: userName.x + 1
            anchors.verticalCenter: avatarFrame.verticalCenter
            anchors.verticalCenterOffset: 2
            width: userName.width
            text: userName.text
            textFormat: Text.PlainText
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font: userName.font
            color: Qt.rgba(0, 0, 0, 0.4)
        }
        Text {
            id: userName
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
            Kirigami.Theme.colorSet: menu.xpChrome ? Kirigami.Theme.Complementary : Kirigami.Theme.Window
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.textColor
        }

        MenuSeparator {
            visible: !menu.xpChrome
            y: menu.xp.headerHeight
            width: parent.width
            height: 1
        }

        // --------------------------------------------------------------
        // Body
        // --------------------------------------------------------------
        Item {
            id: body
            x: menu.frameWidth
            y: menu.xp.headerHeight + 1
            width: parent.width - 2 * menu.frameWidth
            height: menu.bodyHeight

            // ---------------- left column: programs ----------------
            Item {
                id: leftColumn

                readonly property int neededHeight: 5 + leftTop.implicitHeight + allProgramsSeparator.height + 2 + allPrograms.height + 6

                width: menu.xp.leftWidth
                height: parent.height

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
                        xpElement: "startmenu-separator"
                        width: parent.width
                        height: menu.xp.separatorHeight
                        leftInset: 2
                        rightInset: 6
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
                            color: Kirigami.Theme.textColor
                        }
                        Rectangle {
                            anchors.left: queryText.right
                            anchors.leftMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 13
                            color: Kirigami.Theme.textColor

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
                        xpElement: "startmenu-separator"
                        id: searchSeparator
                        anchors.top: searchHeader.bottom
                        width: parent.width
                        height: menu.xp.separatorHeight
                        leftInset: 2
                        rightInset: 6
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
                    xpElement: "startmenu-separator"
                    id: allProgramsSeparator
                    x: 2
                    anchors.bottom: allPrograms.top
                    anchors.bottomMargin: 2
                    width: parent.width - 4
                    height: menu.xp.separatorHeight
                    leftInset: 2
                    rightInset: 6
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

                    // XP's highlight (white text) and green arrow from the
                    // theme, else its view item hover and plain arrow
                    KSvg.FrameSvgItem {
                        anchors.fill: parent
                        imagePath: menu.xpChrome ? "widgets/winxp" : "widgets/viewitem"
                        prefix: menu.xpChrome ? "menu-highlight" : "hover"
                        visible: allPrograms.highlighted
                    }

                    readonly property bool xpArrow: menu.xpChrome
                    readonly property int arrowGap: xpArrow ? 18 : 8

                    Text {
                        id: allProgramsLabel
                        x: Math.round((allPrograms.width - width - allPrograms.arrowGap - allProgramsArrow.width) / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n("All Programs")
                        renderType: Text.NativeRendering
                        font.family: menu.xp.fontFamily
                        font.pixelSize: menu.xp.fontPixelSize
                        font.bold: true
                        color: allPrograms.highlighted && menu.xpChrome ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                    KSvg.SvgItem {
                        id: allProgramsArrow
                        anchors.left: allProgramsLabel.right
                        anchors.leftMargin: allPrograms.arrowGap
                        anchors.verticalCenter: parent.verticalCenter
                        width: allPrograms.xpArrow ? naturalSize.width : 10
                        height: allPrograms.xpArrow ? naturalSize.height : 10
                        svg: allPrograms.xpArrow ? winxp : arrowsSvg
                        elementId: allPrograms.xpArrow ? "startmenu-allprograms-arrow" : "right-arrow"
                    }
                    KSvg.Svg {
                        id: arrowsSvg
                        imagePath: "widgets/arrows"
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

            // Divider between the columns (part of XP's frame)
            KSvg.SvgItem {
                visible: !menu.xpChrome
                x: leftColumn.width
                width: naturalSize.width
                height: parent.height
                imagePath: "widgets/line"
                elementId: "vertical-line"
            }

            // ---------------- right column: places ----------------
            Item {
                id: rightColumn

                readonly property int neededHeight: 5 + placesColumn.implicitHeight + 6

                x: leftColumn.width + 1
                width: menu.xp.rightWidth
                height: parent.height

                Column {
                    id: placesColumn
                    // XP writes the places in dark blue: the theme's header colours
                    Kirigami.Theme.colorSet: menu.xpChrome ? Kirigami.Theme.Header : Kirigami.Theme.Window
                    Kirigami.Theme.inherit: false
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
                                xpElement: "startmenu-places-separator"
                                anchors.fill: parent
                                visible: place.modelData.separator === true
                                leftInset: 52
                                rightInset: 56
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

        }

        MenuSeparator {
            visible: !menu.xpChrome
            y: body.y + body.height
            width: parent.width
            height: 1
        }

        // --------------------------------------------------------------
        // Footer
        // --------------------------------------------------------------
        Item {
            id: footer
            anchors.bottom: parent.bottom
            width: parent.width
            height: menu.xp.footerHeight

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                FooterButton {
                    iconSource: Qt.resolvedUrl("../images/log-off.svg")
                    text: i18n("Log Off")
                    onClicked: menu.controller.logOff()
                }
                FooterButton {
                    iconSource: Qt.resolvedUrl("../images/turn-off.svg")
                    text: i18n("Turn Off Computer")
                    onClicked: menu.controller.turnOff()
                }
            }
        }
    }

    component FooterButton: Item {
        id: footerButton

        readonly property bool hovered: footerMouse.containsMouse
        property string iconSource
        property string text

        signal clicked()

        width: footerRow.width + 6
        height: 30

        // XP's lighter box on the blue footer, else the theme's tool button
        KSvg.FrameSvgItem {
            anchors.fill: parent
            visible: footerMouse.containsMouse
            imagePath: menu.xpChrome ? "widgets/winxp" : "widgets/button"
            prefix: menu.xpChrome ? (footerMouse.pressed ? "startmenu-footer-pressed" : "startmenu-footer-hover")
                                  : (footerMouse.pressed ? "toolbutton-pressed" : "toolbutton-hover")
        }

        Row {
            id: footerRow
            x: 3
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: footerMouse.pressed ? 1 : 0
            spacing: 6

            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                source: footerButton.iconSource
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: footerButton.text
                renderType: Text.NativeRendering
                font.family: menu.xp.fontFamily
                font.pixelSize: menu.xp.fontPixelSize
                Kirigami.Theme.colorSet: menu.xpChrome ? Kirigami.Theme.Complementary : Kirigami.Theme.Window
                Kirigami.Theme.inherit: false
                color: Kirigami.Theme.textColor
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
