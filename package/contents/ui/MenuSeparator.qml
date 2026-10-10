/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Horizontal separator that fades out towards both ends.
*/
import QtQuick

Item {
    id: separator

    property color color: "#cfcfcf"
    property bool fade: true

    implicitHeight: 9

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 1
        color: separator.fade ? "transparent" : separator.color
        gradient: separator.fade ? fadeGradient : null

        Gradient {
            id: fadeGradient
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(separator.color.r, separator.color.g, separator.color.b, 0) }
            GradientStop { position: 0.5; color: separator.color }
            GradientStop { position: 1.0; color: Qt.rgba(separator.color.r, separator.color.g, separator.color.b, 0) }
        }
    }
}
