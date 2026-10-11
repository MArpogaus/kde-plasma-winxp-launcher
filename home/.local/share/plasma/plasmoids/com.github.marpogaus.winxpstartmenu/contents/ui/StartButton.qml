/*
    SPDX-License-Identifier: GPL-2.0-or-later

    The "start" button, drawn with the Plasma theme's button frames
    (widgets/button) and text colour. It scales with the panel thickness;
    at the classic 30 px taskbar it is 100 x 30 px.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Item {
    id: button

    required property QtObject xp
    required property QtObject controller

    property string text: "start"
    property string iconName: ""
    property bool vertical: false
    // In a horizontal panel the button covers the visible taskbar from top
    // to bottom (not just the applet area inside the panel's padding) and,
    // as the first widget, reaches the taskbar's left edge.
    property bool fillPanel: false
    readonly property rect area: fillPanel ? panelArea.rect : Qt.rect(0, 0, width, height)
    readonly property real leftOverflow: area.x < 0 && area.x > -16 ? -area.x : 0
    // The button as drawn on the taskbar; the menu opens right above it
    readonly property alias faceItem: face

    PanelArea {
        id: panelArea
        target: button
    }

    readonly property int thickness: vertical ? width : area.height
    readonly property bool pressedLook: mouseArea.pressed || controller.menuOpen
    readonly property bool hoveredLook: mouseArea.containsMouse && !pressedLook
    // XP draws "start" in Franklin Gothic Medium Italic. The Libre Franklin
    // stand-in matches it best as upright Bold slanted by 8° about the baseline.
    readonly property bool libreFranklin: xp.startFontFamily === "Libre Franklin"
    readonly property matrix4x4 labelSlant: libreFranklin
        ? Qt.matrix4x4(1, -0.14, 0, 0.14 * label.height * 0.75, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        : Qt.matrix4x4()

    Layout.minimumWidth: vertical ? -1 : Math.round(area.height * 3.33) - leftOverflow
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: vertical ? width : -1
    Layout.preferredHeight: Layout.minimumHeight
    Layout.maximumHeight: Layout.minimumHeight

    Item {
        id: face
        x: -button.leftOverflow
        y: button.area.y
        width: button.width + button.leftOverflow
        height: button.area.height

        KSvg.FrameSvgItem {
            anchors.fill: parent
            imagePath: "widgets/button"
            prefix: button.pressedLook ? "pressed" : button.hoveredLook ? "hover" : "normal"
        }

        // XP's flag is 20 px at x = 10 on a 30 px taskbar
        Kirigami.Icon {
            x: button.vertical ? Math.round((parent.width - width) / 2) : Math.round(button.thickness * 0.34)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(button.thickness * 0.667)
            height: width
            source: button.iconName
            roundToIconSize: false
        }

        Text {
            id: label
            visible: !button.vertical
            x: Math.round(button.thickness * 1.17)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            text: button.text
            textFormat: Text.PlainText
            // Grey antialiasing: the panel's native rendering adds colour fringes
            renderType: Text.QtRendering
            font.family: button.xp.startFontFamily
            font.pixelSize: Math.round(button.thickness * 0.567)
            font.italic: !button.libreFranklin
            font.weight: button.libreFranklin ? Font.Bold : Font.Medium
            transform: Matrix4x4 { matrix: button.labelSlant }
            color: Kirigami.Theme.textColor
        }

        MouseArea {
            id: mouseArea

            property bool wasOpen: false

            anchors.fill: parent
            hoverEnabled: true
            onPressed: wasOpen = button.controller.menuOpenOrJustClosed()
            onClicked: {
                if (wasOpen) {
                    button.controller.closeMenu();
                } else {
                    button.controller.openMenu();
                }
            }
        }
    }
}
