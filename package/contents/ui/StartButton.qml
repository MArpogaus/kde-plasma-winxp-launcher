/*
    SPDX-License-Identifier: GPL-2.0-or-later

    The green Luna "start" button. It scales with the panel thickness;
    at the classic 30 px taskbar it is 99 x 30 px.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: button

    required property QtObject xp
    required property QtObject controller

    property string text: "start"
    property string iconName: ""
    property bool vertical: false

    readonly property int thickness: vertical ? width : height
    readonly property bool pressedLook: mouseArea.pressed || controller.menuOpen
    readonly property bool hoveredLook: mouseArea.containsMouse && !pressedLook

    Layout.minimumWidth: vertical ? -1 : Math.round(height * 3.3)
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: vertical ? width : -1
    Layout.preferredHeight: Layout.minimumHeight
    Layout.maximumHeight: Layout.minimumHeight

    Gradient {
        id: normalGradient
        GradientStop { position: 0.00; color: "#3a8b39" }
        GradientStop { position: 0.04; color: "#7cc874" }
        GradientStop { position: 0.10; color: "#5db556" }
        GradientStop { position: 0.24; color: "#45a142" }
        GradientStop { position: 0.50; color: "#3d9a3c" }
        GradientStop { position: 0.78; color: "#378f36" }
        GradientStop { position: 0.92; color: "#2f842f" }
        GradientStop { position: 1.00; color: "#2a6d29" }
    }
    Gradient {
        id: hoverGradient
        GradientStop { position: 0.00; color: "#45a043" }
        GradientStop { position: 0.04; color: "#93d98a" }
        GradientStop { position: 0.10; color: "#70c868" }
        GradientStop { position: 0.24; color: "#55b551" }
        GradientStop { position: 0.50; color: "#4cae4a" }
        GradientStop { position: 0.78; color: "#45a243" }
        GradientStop { position: 0.92; color: "#3b963a" }
        GradientStop { position: 1.00; color: "#317e30" }
    }
    Gradient {
        id: pressedGradient
        GradientStop { position: 0.00; color: "#24612a" }
        GradientStop { position: 0.06; color: "#2d7a2f" }
        GradientStop { position: 0.20; color: "#2f7f31" }
        GradientStop { position: 0.50; color: "#328532" }
        GradientStop { position: 0.85; color: "#2f8030" }
        GradientStop { position: 1.00; color: "#2b6f2b" }
    }

    Item {
        anchors.fill: parent
        clip: true

        // Rounded on the right only: the left corners are pushed outside.
        Rectangle {
            id: shape
            x: button.vertical ? 0 : -radius
            width: parent.width + (button.vertical ? 0 : radius)
            height: parent.height
            radius: button.vertical ? 3 : Math.round(button.thickness * 0.42)
            gradient: button.pressedLook ? pressedGradient : button.hoveredLook ? hoverGradient : normalGradient
            border.width: 1
            border.color: button.pressedLook ? "#1d4f1d" : "#2a6e29"

            // Soft glow behind the flag
            Rectangle {
                x: shape.radius
                width: parent.width * 0.45
                height: parent.height
                opacity: button.pressedLook ? 0.0 : 1.0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            // Shading along the rounded right edge
            Rectangle {
                anchors.right: parent.right
                width: shape.radius * 1.6
                height: parent.height
                radius: shape.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.22) }
                }
            }
        }
    }

    Item {
        id: flag
        x: button.vertical ? Math.round((parent.width - width) / 2) : Math.round(button.thickness * 0.2)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: button.pressedLook ? 1 : 0
        width: Math.round(button.thickness * 0.7)
        height: width

        Image {
            anchors.fill: parent
            visible: button.iconName.length === 0
            source: "../images/start-flag.svg"
            sourceSize: Qt.size(width, height)
            smooth: true
        }
        Kirigami.Icon {
            anchors.fill: parent
            visible: button.iconName.length > 0
            source: button.iconName
            roundToIconSize: false
        }
    }

    Text {
        id: labelShadow
        visible: !button.vertical
        x: label.x + 1
        y: label.y + 1
        text: label.text
        font: label.font
        color: Qt.rgba(0.08, 0.2, 0.08, 0.75)
    }
    Text {
        id: label
        visible: !button.vertical
        x: flag.x + flag.width + Math.round(button.thickness * 0.08)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: button.pressedLook ? 0 : -1
        text: button.text
        textFormat: Text.PlainText
        font.family: button.xp.startFontFamily
        font.pixelSize: Math.round(button.thickness * 0.62)
        font.italic: true
        font.bold: true
        color: "#ffffff"
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
