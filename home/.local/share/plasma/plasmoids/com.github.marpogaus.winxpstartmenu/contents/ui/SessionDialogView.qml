/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP's "Turn off computer" and "Log Off Windows" dialogs: dark blue title
    band with the flag, light blue band with the big buttons, dark blue
    band with Cancel. 313 x 198 px like the original.
*/
import QtQuick
import org.kde.kirigami as Kirigami

FocusScope {
    id: view

    required property QtObject xp

    // "turnoff" or "logoff"
    property string mode: "turnoff"
    property string flagIcon: ""

    signal activated(string action)

    readonly property var options: mode === "logoff"
        ? [
            { action: "switchuser", icon: "../images/switch-user.svg", text: i18n("Switch User") },
            { action: "logoff", icon: "../images/log-off.svg", text: i18n("Log Off") }
        ]
        : [
            { action: "standby", icon: "../images/stand-by.svg", text: i18n("Stand By") },
            { action: "turnoff", icon: "../images/turn-off.svg", text: i18n("Turn Off") },
            { action: "restart", icon: "../images/restart.svg", text: i18n("Restart") }
        ]

    width: 313
    height: 198
    focus: true

    Keys.onEscapePressed: activated("cancel")

    // Title band
    Rectangle {
        id: titleBand
        width: parent.width
        height: 48
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0d36a6" }
            GradientStop { position: 0.5; color: "#0a2f9b" }
            GradientStop { position: 1.0; color: "#082a8e" }
        }

        Text {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: view.mode === "logoff" ? i18n("Log Off Windows") : i18n("Turn off computer")
            renderType: Text.NativeRendering
            font.family: view.xp.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: "#ffffff"
        }

        Item {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36

            Image {
                anchors.fill: parent
                visible: view.flagIcon.length === 0
                source: "../images/start-flag.svg"
                sourceSize: Qt.size(width, height)
            }
            Kirigami.Icon {
                anchors.fill: parent
                anchors.margins: 4
                visible: view.flagIcon.length > 0
                source: view.flagIcon
                roundToIconSize: false
            }
        }
    }

    // Button band
    Rectangle {
        id: optionsBand
        y: titleBand.height
        width: parent.width
        height: 104
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#6b90f0" }
            GradientStop { position: 1.0; color: "#4d72dc" }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#8eabf3"
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#3a5cc9"
        }

        Repeater {
            model: view.options

            delegate: Item {
                id: option

                required property var modelData
                required property int index

                readonly property real slot: optionsBand.width / (view.options.length + 1)

                x: Math.round(slot * (index + 1) - width / 2)
                y: 22
                width: 76
                height: 62

                Item {
                    id: iconBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: optionMouse.pressed ? 1 : 0
                    y: optionMouse.pressed ? 1 : 0
                    width: 33
                    height: 33

                    Image {
                        anchors.fill: parent
                        source: option.modelData.icon
                        sourceSize: Qt.size(33, 33)
                    }
                    // Hover: the button lights up
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 3
                        color: "#ffffff"
                        opacity: optionMouse.containsMouse && !optionMouse.pressed ? 0.25 : 0
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: iconBox.y + iconBox.height + 6
                    text: option.modelData.text
                    renderType: Text.NativeRendering
                    font.family: view.xp.fontFamily
                    font.pixelSize: 11
                    color: "#ffffff"
                }

                MouseArea {
                    id: optionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: view.activated(option.modelData.action)
                }
            }
        }
    }

    // Cancel band
    Rectangle {
        y: optionsBand.y + optionsBand.height
        width: parent.width
        height: parent.height - y
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a2f9b" }
            GradientStop { position: 1.0; color: "#082a8e" }
        }

        // XP push button
        Rectangle {
            id: cancelButton
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 75
            height: 23
            radius: 3
            border.width: 1
            border.color: "#003c74"
            gradient: Gradient {
                GradientStop { position: 0.0; color: cancelMouse.pressed ? "#e3e2da" : "#ffffff" }
                GradientStop { position: 0.85; color: cancelMouse.pressed ? "#e6e5dd" : "#f0f0ea" }
                GradientStop { position: 1.0; color: cancelMouse.pressed ? "#f4f3ee" : "#d6d0c5" }
            }

            // Hover: XP's orange inner glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 2
                color: "transparent"
                border.width: 2
                border.color: "#f8b330"
                visible: cancelMouse.containsMouse && !cancelMouse.pressed
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: cancelMouse.pressed ? 1 : 0
                anchors.verticalCenterOffset: cancelMouse.pressed ? 1 : 0
                text: i18n("Cancel")
                renderType: Text.NativeRendering
                font.family: view.xp.fontFamily
                font.pixelSize: 11
                color: "#000000"
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: view.activated("cancel")
            }
        }
    }
}
