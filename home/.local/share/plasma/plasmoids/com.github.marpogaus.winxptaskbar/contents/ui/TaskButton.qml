/*
    SPDX-License-Identifier: GPL-2.0-or-later

    One taskbar button, drawn with the Plasma theme's task button frames
    (widgets/tasks, as Plasma's own task manager does) and its text colour.
*/
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Item {
    id: button

    property var icon
    property string text
    property string fontFamily: "Tahoma"
    property bool active: false
    property bool attention: false
    property bool minimized: false
    property bool hovered: false
    property bool pressed: false

    readonly property bool down: active || pressed
    readonly property bool truncated: label.truncated

    KSvg.FrameSvgItem {
        anchors.fill: parent
        imagePath: "widgets/tasks"
        // Like Plasma's task manager; themes without a state fall back to normal
        prefix: button.attention && !button.active ? ["attention", "normal"]
              : button.down ? ["focus", "normal"]
              : button.hovered ? ["hover", "normal"]
              : button.minimized ? ["minimized", "normal"]
              : "normal"
    }

    Kirigami.Icon {
        id: iconItem
        x: 7 + (button.down ? 1 : 0)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: button.down ? 1 : 0
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
        anchors.verticalCenterOffset: button.down ? 1 : 0
        text: button.text
        textFormat: Text.PlainText
        elide: Text.ElideRight
        renderType: Text.NativeRendering
        font.family: button.fontFamily
        font.pixelSize: 11
        // Text on the taskbar: the colour set for contrasting areas
        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        Kirigami.Theme.inherit: false
        color: Kirigami.Theme.textColor
    }
}
