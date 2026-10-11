/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Horizontal separator: a line that fades in and out at both ends, as
    in XP's start menu and its cascading menus, or a plain one (Luna's
    ordinary menus).
*/
import QtQuick

Item {
    id: separator

    property color color: "#d6d6d6"
    property int leftInset: 0
    property int rightInset: 0
    property bool fade: true
    // XP fades the line in and out over about 28 px at each end
    property int fadeLength: 28

    implicitHeight: 8

    Rectangle {
        id: line
        x: separator.leftInset
        // On the 5th of XP's 8 rows
        y: Math.ceil((parent.height - 1) / 2)
        width: parent.width - separator.leftInset - separator.rightInset
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: separator.fade ? Qt.rgba(separator.color.r, separator.color.g, separator.color.b, 0) : separator.color }
            GradientStop { position: Math.min(0.5, separator.fadeLength / Math.max(1, line.width)); color: separator.color }
            GradientStop { position: Math.max(0.5, 1 - separator.fadeLength / Math.max(1, line.width)); color: separator.color }
            GradientStop { position: 1.0; color: separator.fade ? Qt.rgba(separator.color.r, separator.color.g, separator.color.b, 0) : separator.color }
        }
    }
}
