/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Horizontal separator. In the start menu the line is inset and fades
    out towards both ends; in cascading menus it is a plain line.
*/
import QtQuick

Item {
    id: separator

    property color color: "#d6d6d6"
    property bool fade: true
    property int leftInset: 0
    property int rightInset: 0

    implicitHeight: 8

    Rectangle {
        x: separator.leftInset
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - separator.leftInset - separator.rightInset
        height: 1
        color: separator.fade ? "transparent" : separator.color
        gradient: separator.fade ? fadeGradient : null

        Gradient {
            id: fadeGradient
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(separator.color.r, separator.color.g, separator.color.b, 0) }
            GradientStop { position: 0.3; color: separator.color }
            GradientStop { position: 0.7; color: separator.color }
            GradientStop { position: 1.0; color: Qt.rgba(separator.color.r, separator.color.g, separator.color.b, 0) }
        }
    }
}
