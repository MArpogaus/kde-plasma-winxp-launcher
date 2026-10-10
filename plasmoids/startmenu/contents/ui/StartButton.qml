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
    // XP's start button touches the screen edge. When we are the first
    // widget of a horizontal panel, extend left over the panel theme's
    // margin; the height always stays what the panel gives us.
    property bool flushLeft: false
    readonly property real windowX: {
        Window.width;
        for (let item = button; item; item = item.parent) {
            item.x;
        }
        return Window.window ? mapToItem(null, 0, 0).x : 0;
    }
    readonly property real leftOverflow: flushLeft && !vertical && windowX > 0 && windowX < 16 ? windowX : 0

    readonly property int thickness: vertical ? width : height
    readonly property bool pressedLook: mouseArea.pressed || controller.menuOpen
    readonly property bool hoveredLook: mouseArea.containsMouse && !pressedLook

    Layout.minimumWidth: vertical ? -1 : Math.round(height * 3.3) - leftOverflow
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: vertical ? width : -1
    Layout.preferredHeight: Layout.minimumHeight
    Layout.maximumHeight: Layout.minimumHeight

    // Sampled from a real XP taskbar (rows of a 30 px button)
    Gradient {
        id: normalGradient
        GradientStop {
            position: 0.00
            color: "#1d4b1d"
        }
        GradientStop {
            position: 0.04
            color: "#2b6b2b"
        }
        GradientStop {
            position: 0.09
            color: "#3e8d3b"
        }
        GradientStop {
            position: 0.15
            color: "#2b912d"
        }
        GradientStop {
            position: 0.25
            color: "#1d8d20"
        }
        GradientStop {
            position: 0.55
            color: "#1b8c1b"
        }
        GradientStop {
            position: 0.80
            color: "#1e941c"
        }
        GradientStop {
            position: 0.90
            color: "#1f8e1e"
        }
        GradientStop {
            position: 0.95
            color: "#1c7c1e"
        }
        GradientStop {
            position: 1.00
            color: "#0e5c12"
        }
    }
    Gradient {
        id: hoverGradient
        GradientStop {
            position: 0.00
            color: "#266026"
        }
        GradientStop {
            position: 0.04
            color: "#368236"
        }
        GradientStop {
            position: 0.09
            color: "#4fa64b"
        }
        GradientStop {
            position: 0.15
            color: "#37a63a"
        }
        GradientStop {
            position: 0.25
            color: "#28a22b"
        }
        GradientStop {
            position: 0.55
            color: "#26a126"
        }
        GradientStop {
            position: 0.80
            color: "#2aaa27"
        }
        GradientStop {
            position: 0.90
            color: "#2aa229"
        }
        GradientStop {
            position: 0.95
            color: "#258f27"
        }
        GradientStop {
            position: 1.00
            color: "#12701a"
        }
    }
    Gradient {
        id: pressedGradient
        GradientStop {
            position: 0.00
            color: "#0f350f"
        }
        GradientStop {
            position: 0.06
            color: "#17641a"
        }
        GradientStop {
            position: 0.15
            color: "#167a18"
        }
        GradientStop {
            position: 0.55
            color: "#157e16"
        }
        GradientStop {
            position: 0.85
            color: "#188a18"
        }
        GradientStop {
            position: 0.95
            color: "#17741a"
        }
        GradientStop {
            position: 1.00
            color: "#0b4f0f"
        }
    }

    Item {
        id: face
        x: -button.leftOverflow
        width: button.width + button.leftOverflow
        height: button.height

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
                border.color: "#0b4f12"

                // Darker band along the left edge
                Rectangle {
                    x: shape.radius
                    width: 6
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(0, 0.12, 0, 0.55)
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
            color: Qt.rgba(0, 0, 0, 0.22)
        }
        Text {
            visible: !button.vertical
            x: label.x + 1
            y: label.y + 1
            text: label.text
            font: label.font
            color: Qt.rgba(0, 0.08, 0, 0.7)
        }
        Text {
            id: label
            visible: !button.vertical
            x: Math.round(button.thickness * 1.13) + (button.pressedLook ? 1 : 0)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: button.pressedLook ? 0 : -1
            text: button.text
            textFormat: Text.PlainText
            font.family: button.xp.startFontFamily
            font.pixelSize: Math.round(button.thickness * 0.6)
            font.letterSpacing: -0.5
            font.italic: true
            font.weight: Font.Medium
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
