/*
    SPDX-License-Identifier: GPL-2.0-or-later

    One Luna taskbar button. Colours are sampled row by row from a 25 px
    tall XP button; the gradient stretches for other heights.
*/
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: button

    property var icon
    property string text
    property string fontFamily: "Tahoma"
    property bool active: false
    property bool attention: false
    property bool hovered: false
    property bool pressed: false

    readonly property string look: attention && !active ? "attention"
                                   : active || pressed ? (hovered ? "activeHover" : "active")
                                   : hovered ? "hover" : "normal"
    readonly property bool truncated: label.truncated

    // [outer border, left highlight, right shade, rows...]
    readonly property var palettes: ({
        normal: ["#2b62cf", "#639bfb", "#3676eb",
                 ["#519af6", "#5a98f2", "#488bf2", "#4083f1", "#3d82f4", "#3b7ff4", "#3a82f4", "#3980f4", "#3980f4", "#3982f4", "#316fe8"]],
        hover: ["#2554ad", "#99c8ff", "#2d86ff",
                ["#8ec6ff", "#7cb9ff", "#69abff", "#5ea9ff", "#59a4ff", "#59a1ff", "#55a3ff", "#55a0ff", "#55a0ff", "#59a4ff", "#2a81ff"]],
        active: ["#0e3a9a", "#144096", "#1f55b8",
                 ["#123c92", "#184aa6", "#164fbc", "#1650bc", "#174dbb", "#174eba", "#184eb8", "#194fb8", "#1a50b8", "#1c53b8", "#2057b9"]],
        activeHover: ["#0e3a9a", "#1a4ba6", "#2a64c6",
                      ["#163f97", "#1d52b3", "#1d58c8", "#1d59c8", "#1e57c7", "#1e58c6", "#1f58c4", "#2059c4", "#215ac4", "#235dc4", "#2861c6"]],
        attention: ["#b86200", "#ffb649", "#e1800c",
                    ["#ffbe58", "#f39118", "#ea810f", "#e77e0c", "#e57c0a", "#e47b09", "#e37a08", "#e37a08", "#e37a08", "#e27907", "#e17c0c"]]
    })
    readonly property var colors: palettes[look]

    Rectangle {
        anchors.fill: parent
        radius: 3
        color: button.colors[0]

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0.00; color: button.colors[3][0] }
                GradientStop { position: 0.06; color: button.colors[3][1] }
                GradientStop { position: 0.12; color: button.colors[3][2] }
                GradientStop { position: 0.18; color: button.colors[3][3] }
                GradientStop { position: 0.26; color: button.colors[3][4] }
                GradientStop { position: 0.34; color: button.colors[3][5] }
                GradientStop { position: 0.42; color: button.colors[3][6] }
                GradientStop { position: 0.50; color: button.colors[3][7] }
                GradientStop { position: 0.85; color: button.colors[3][8] }
                GradientStop { position: 0.93; color: button.colors[3][9] }
                GradientStop { position: 1.00; color: button.colors[3][10] }
            }
        }

        // Bevel: light inner line on the left, darker on the right
        Rectangle {
            x: 1
            y: 2
            width: 1
            height: parent.height - 4
            color: button.colors[1]
        }
        Rectangle {
            x: parent.width - 2
            y: 2
            width: 1
            height: parent.height - 4
            color: button.colors[2]
        }
    }

    Kirigami.Icon {
        id: iconItem
        x: 7 + (button.active ? 1 : 0)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: button.active ? 1 : 0
        width: 16
        height: 16
        source: button.icon ?? ""
        roundToIconSize: false
        animated: false
    }

    Text {
        id: label
        anchors.left: iconItem.right
        anchors.leftMargin: 4
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: button.active ? 1 : 0
        text: button.text
        textFormat: Text.PlainText
        elide: Text.ElideRight
        renderType: Text.NativeRendering
        font.family: button.fontFamily
        font.pixelSize: 11
        color: "#ffffff"
    }
}
