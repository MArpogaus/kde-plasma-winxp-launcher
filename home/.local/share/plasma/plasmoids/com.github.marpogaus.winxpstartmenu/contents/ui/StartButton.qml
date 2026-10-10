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
    // In a horizontal panel the button covers the visible taskbar from top
    // to bottom (not just the applet area inside the panel's padding) and,
    // as the first widget, reaches the taskbar's left edge.
    property bool fillPanel: false
    readonly property rect area: fillPanel && !vertical ? panelArea.rect : Qt.rect(0, 0, width, height)
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

    Layout.minimumWidth: vertical ? -1 : Math.round(area.height * 3.3) - leftOverflow
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: vertical ? width : -1
    Layout.preferredHeight: Layout.minimumHeight
    Layout.maximumHeight: Layout.minimumHeight

    // Sampled row by row from XP's start button between the flag and the
    // label (30 px tall); hover and pressed are overlays on it
    Gradient {
        id: normalGradient
        GradientStop {
            position: 0.02
            color: "#4f9250"
        }
        GradientStop {
            position: 0.08
            color: "#8bbe8c"
        }
        GradientStop {
            position: 0.15
            color: "#74af74"
        }
        GradientStop {
            position: 0.22
            color: "#5aa05a"
        }
        GradientStop {
            position: 0.32
            color: "#479647"
        }
        GradientStop {
            position: 0.42
            color: "#3f983f"
        }
        GradientStop {
            position: 0.55
            color: "#3da63e"
        }
        GradientStop {
            position: 0.68
            color: "#3eaf3e"
        }
        GradientStop {
            position: 0.78
            color: "#3dab3d"
        }
        GradientStop {
            position: 0.85
            color: "#399e39"
        }
        GradientStop {
            position: 0.92
            color: "#328531"
        }
        GradientStop {
            position: 0.95
            color: "#2b722b"
        }
        GradientStop {
            position: 0.98
            color: "#255f2f"
        }
    }

    Item {
        id: face
        x: -button.leftOverflow
        y: button.area.y
        width: button.width + button.leftOverflow
        height: button.area.height

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
                gradient: normalGradient

                // Hover lightens, pressed darkens
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: button.hoveredLook || button.pressedLook
                    color: button.pressedLook ? Qt.rgba(0, 0.1, 0, 0.3) : Qt.rgba(1, 1, 1, 0.12)
                }

                // Darker band along the left edge
                Rectangle {
                    x: shape.radius
                    width: 3
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(0, 0.12, 0, 0.4)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(0, 0.12, 0, 0.0)
                        }
                    }
                }

                // Shading along the rounded right edge
                Rectangle {
                    anchors.right: parent.right
                    width: shape.radius * 1.4
                    height: parent.height
                    radius: shape.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(0, 0.1, 0, 0.0)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(0, 0.1, 0, 0.35)
                        }
                    }
                }
            }
        }

        Item {
            id: flag
            // The built-in flag fills ~75 % of its box. A custom icon (XP's 20 px
            // start_flag.png) fills its box: 20 px at x = 8 on a 30 px taskbar.
            readonly property bool custom: button.iconName.length > 0
            x: button.vertical ? Math.round((parent.width - width) / 2) : Math.round(button.thickness * (custom ? 0.27 : 0.23))
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: button.pressedLook ? 1 : 0
            width: Math.round(button.thickness * (custom ? 0.667 : 0.84))
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
            visible: !button.vertical
            x: label.x + 2
            y: label.y + 2
            text: label.text
            font: label.font
            renderType: label.renderType
            transform: Matrix4x4 { matrix: button.labelSlant }
            color: Qt.rgba(0, 0, 0, 0.22)
        }
        Text {
            visible: !button.vertical
            x: label.x + 1
            y: label.y + 1
            text: label.text
            font: label.font
            renderType: label.renderType
            transform: Matrix4x4 { matrix: button.labelSlant }
            color: Qt.rgba(0, 0.08, 0, 0.7)
        }
        Text {
            id: label
            visible: !button.vertical
            x: Math.round(button.thickness * 1.17) + (button.pressedLook ? 1 : 0)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: button.pressedLook ? 2 : 1
            text: button.text
            textFormat: Text.PlainText
            // Grey antialiasing: the panel's native rendering adds colour fringes
            renderType: Text.QtRendering
            font.family: button.xp.startFontFamily
            font.pixelSize: Math.round(button.thickness * 0.567)
            font.italic: !button.libreFranklin
            font.weight: button.libreFranklin ? Font.Bold : Font.Medium
            transform: Matrix4x4 { matrix: button.labelSlant }
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
}
