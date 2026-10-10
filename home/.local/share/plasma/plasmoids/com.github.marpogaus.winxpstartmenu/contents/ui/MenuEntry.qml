/*
    SPDX-License-Identifier: GPL-2.0-or-later

    One row of the start menu or of a cascading menu: icon, title,
    optional grey subtitle and optional cascade arrow.
*/
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: entry

    required property QtObject xp

    property var iconSource
    property string title
    property string subtitle
    property bool bold: false
    property bool showArrow: false
    property bool interactive: true
    property int iconSize: 30
    property int leftPadding: 2
    property int textSpacing: 4
    property color textColor: xp.leftText
    property bool wrap: false
    // Wrapped titles break at this width (0: the full row)
    property int wrapWidth: 0
    readonly property real labelsHeight: labels.implicitHeight

    // Kept highlighted by the owner, e.g. while its cascade is open.
    property bool forceHighlight: false
    property color highlightColor: xp.highlight
    // Applications can be dragged (to Quick Launch, the desktop, …): the
    // .desktop URL and an object with startDrag(url, icon)
    property url dragUrl
    property QtObject dragController: null
    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool highlighted: entry.interactive && (hovered || forceHighlight)

    signal clicked()
    signal contextMenuRequested(real x, real y)

    implicitHeight: Math.max(iconSize + 2, 18)

    Rectangle {
        anchors.fill: parent
        color: entry.highlightColor
        visible: entry.highlighted
    }

    Kirigami.Icon {
        id: icon
        x: entry.leftPadding
        anchors.verticalCenter: parent.verticalCenter
        width: entry.iconSize
        height: entry.iconSize
        visible: entry.iconSize > 0
        source: entry.iconSource ?? ""
        roundToIconSize: false
        animated: false
    }

    Column {
        id: labels
        anchors.verticalCenter: parent.verticalCenter
        x: icon.x + entry.iconSize + entry.textSpacing
        width: parent.width - x - (entry.showArrow ? 14 : 4)
        spacing: 0

        Text {
            width: entry.wrap && entry.wrapWidth > 0 ? Math.min(entry.wrapWidth, parent.width) : parent.width
            text: entry.title
            textFormat: Text.PlainText
            lineHeightMode: Text.FixedHeight
            lineHeight: 12
            wrapMode: entry.wrap ? Text.WordWrap : Text.NoWrap
            maximumLineCount: entry.wrap ? 2 : 1
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            renderType: Text.NativeRendering
            font.family: entry.xp.fontFamily
            font.pixelSize: entry.xp.fontPixelSize
            font.bold: entry.bold
            color: !entry.interactive ? entry.xp.disabledText
                 : entry.highlighted ? entry.xp.highlightText : entry.textColor
        }

        Text {
            width: parent.width
            visible: entry.subtitle.length > 0
            text: entry.subtitle
            textFormat: Text.PlainText
            lineHeightMode: Text.FixedHeight
            lineHeight: 12
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font.family: entry.xp.fontFamily
            font.pixelSize: entry.xp.fontPixelSize
            color: entry.highlighted ? entry.xp.highlightText : entry.xp.subtitleText
        }
    }

    Image {
        anchors.right: parent.right
        anchors.rightMargin: 6
        // On whole pixels, so the arrow stays crisp
        y: Math.floor((parent.height - height) / 2)
        visible: entry.showArrow
        source: entry.highlighted ? "../images/arrow-white.svg" : "../images/arrow.svg"
        sourceSize: Qt.size(4, 7)
        smooth: false
    }

    DragHandler {
        target: null
        enabled: entry.dragController !== null && entry.dragUrl.toString() !== ""
        onActiveChanged: if (active) entry.dragController.startDrag(entry.dragUrl, entry.iconSource)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: entry.interactive
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                entry.contextMenuRequested(mouse.x, mouse.y);
            } else {
                entry.clicked();
            }
        }
    }
}
